`timescale 1ns/1ps

module tb;
  localparam int CLKS_PER_BIT = 4;

  logic clk;
  logic rst_n;
  logic [7:0] data_i;
  logic valid_i;
  logic ready_o;
  logic tx_o;
  logic busy_o;
  logic done_pulse_o;

  int errors;

  uart_tx #(
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .data_i(data_i),
      .valid_i(valid_i),
      .ready_o(ready_o),
      .tx_o(tx_o),
      .busy_o(busy_o),
      .done_pulse_o(done_pulse_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  function automatic logic expected_frame_bit(
      input logic [7:0] data,
      input int frame_index
  );
    begin
      if (frame_index == 0)
        expected_frame_bit = 1'b0;              // start bit
      else if (frame_index == 9)
        expected_frame_bit = 1'b1;              // stop bit
      else
        expected_frame_bit = data[frame_index-1]; // LSB-first data bits
    end
  endfunction

  task automatic fail(input string msg);
    begin
      $display("FAIL %s", msg);
      errors++;
    end
  endtask

  task automatic reset_dut;
    begin
      rst_n = 1'b0;
      data_i = '0;
      valid_i = 1'b0;

      repeat (4) @(posedge clk);

      rst_n = 1'b1;
      @(posedge clk);

      if (tx_o !== 1'b1)
        fail("tx_o must idle high after reset");

      if (ready_o !== 1'b1)
        fail("ready_o must be high when idle");

      if (busy_o !== 1'b0)
        fail("busy_o must be low after reset");

      if (done_pulse_o !== 1'b0)
        fail("done_pulse_o must be low after reset");
    end
  endtask

  task automatic launch_byte(input logic [7:0] data);
    begin
      wait (ready_o === 1'b1);

      @(negedge clk);
      data_i = data;
      valid_i = 1'b1;

      // Byte is accepted on this rising edge if ready_o is high.
      @(posedge clk);

      @(negedge clk);
      valid_i = 1'b0;
      data_i = '0;
    end
  endtask

  task automatic wait_done_exactly_one_cycle;
    int timeout;
    begin
      timeout = CLKS_PER_BIT * 20;

      while ((done_pulse_o !== 1'b1) && (timeout > 0)) begin
        @(posedge clk);
        timeout--;
      end

      if (timeout == 0) begin
        fail("done_pulse_o never asserted");
      end else begin
        @(posedge clk);
        if (done_pulse_o !== 1'b0)
          fail("done_pulse_o must be exactly one cycle");
      end
    end
  endtask

  task automatic check_frame(input logic [7:0] data);
    logic exp_bit;
    begin
      for (int frame_index = 0; frame_index < 10; frame_index++) begin

        // Sample near the middle of each UART bit.
        repeat (CLKS_PER_BIT / 2) @(posedge clk);

        exp_bit = expected_frame_bit(data, frame_index);

        if (tx_o !== exp_bit) begin
          $display(
            "FAIL tx bit frame_index=%0d got=%0b exp=%0b",
            frame_index,
            tx_o,
            exp_bit
          );
          errors++;
        end

        // During start + data bits, transmitter must be busy.
        // For frame_index 9, stop bit is still active, but ready may return
        // right after the stop bit finishes, so don't check ready here.
        if (frame_index < 9) begin
          if (ready_o !== 1'b0)
            fail("ready_o must stay low while frame is active");

          if (busy_o !== 1'b1)
            fail("busy_o must stay high while frame is active");

          if (done_pulse_o !== 1'b0)
            fail("done_pulse_o must stay low before frame completes");
        end

        // Finish the rest of this UART bit period.
        repeat (CLKS_PER_BIT - (CLKS_PER_BIT / 2)) @(posedge clk);
      end

      wait_done_exactly_one_cycle();

      if (tx_o !== 1'b1)
        fail("tx_o must return to idle high");

      if (busy_o !== 1'b0)
        fail("busy_o must clear after frame");

      if (ready_o !== 1'b1)
        fail("ready_o must return high after frame");
    end
  endtask

  task automatic try_rejected_byte_while_busy(input logic [7:0] data);
    begin
      // Wait until we are clearly inside the active UART frame.
      repeat (CLKS_PER_BIT * 2) @(posedge clk);

      if (ready_o !== 1'b0)
        fail("ready_o must reject new bytes while busy");

      if (busy_o !== 1'b1)
        fail("busy_o must stay high while busy");

      @(negedge clk);
      data_i = data;
      valid_i = 1'b1;

      // Keep valid_i high while DUT is busy.
      // A correct UART TX must ignore this because ready_o is low.
      repeat (CLKS_PER_BIT * 2) begin
        @(posedge clk);

        if (ready_o !== 1'b0)
          fail("ready_o must stay low while rejecting byte during busy");

        if (busy_o !== 1'b1)
          fail("busy_o must stay high while rejecting byte during busy");
      end

      @(negedge clk);
      valid_i = 1'b0;
      data_i = '0;
    end
  endtask

  initial begin
    errors = 0;
    reset_dut();

    // Basic frame test.
    launch_byte(8'hA5);
    check_frame(8'hA5);

    // Important: check_frame must run at the same time as the rejected-byte test.
    // The old testbench waited several bit periods, then tried to check frame_index 0,
    // which was already too late.
    launch_byte(8'h3C);

    fork
      begin
        check_frame(8'h3C);
      end

      begin
        try_rejected_byte_while_busy(8'hFF);
      end
    join

    // Make sure no accidental extra byte started after the rejected attempt.
    repeat (CLKS_PER_BIT * 2) @(posedge clk);

    if (tx_o !== 1'b1)
      fail("tx_o should remain idle after rejected byte");

    if (busy_o !== 1'b0)
      fail("busy_o should remain low after rejected byte");

    if (ready_o !== 1'b1)
      fail("ready_o should remain high after rejected byte");

    if (errors == 0) begin
      $display("PASS p02_uart_tx");
      $finish;
    end else begin
      $display("FAIL p02_uart_tx errors=%0d", errors);
      $fatal(1);
    end
  end

endmodule

