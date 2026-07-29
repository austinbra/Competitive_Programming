`timescale 1ns/1ps

module tb;
  localparam int CLKS_PER_BIT = 8;

  logic clk = 1'b0;
  logic rst_n;
  logic rx_i;
  logic [7:0] data_o;
  logic valid_o;
  logic framing_error_o;
  logic busy_o;

  logic [7:0] expected [0:127];
  int expected_wr;
  int expected_rd;
  int framing_errors;
  int errors;

  always #5 clk = ~clk;

  uart_rx #(
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) dut (.*);

  task automatic fail(input string msg);
    begin
      $display("FAIL %s", msg);
      errors++;
    end
  endtask

  always @(posedge clk) begin
    #1;
    if (rst_n && valid_o) begin
      if (expected_rd >= expected_wr) begin
        fail("valid_o asserted without an expected byte");
      end else if (data_o !== expected[expected_rd]) begin
        $display("FAIL UART byte index=%0d got=%02h expected=%02h",
                 expected_rd, data_o, expected[expected_rd]);
        errors++;
      end
      expected_rd++;
    end

    if (rst_n && framing_error_o)
      framing_errors++;
  end

  task automatic expect_byte(input logic [7:0] value);
    begin
      expected[expected_wr] = value;
      expected_wr++;
    end
  endtask

  task automatic send_bit(input logic level);
    begin
      @(negedge clk);
      rx_i = level;
      repeat (CLKS_PER_BIT) @(posedge clk);
    end
  endtask

  task automatic send_frame(
      input logic [7:0] value,
      input logic       good_stop
  );
    begin
      send_bit(1'b0); // Start bit.
      for (int bit_idx = 0; bit_idx < 8; bit_idx++)
        send_bit(value[bit_idx]);
      send_bit(good_stop); // Stop bit should be high.
    end
  endtask

  initial begin
    #100000;
    $fatal(1, "FAIL timeout in p10_uart_rx");
  end

  initial begin
    errors = 0;
    expected_wr = 0;
    expected_rd = 0;
    framing_errors = 0;
    rst_n = 1'b0;
    rx_i = 1'b1;

    repeat (5) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    repeat (3) @(posedge clk);

    // A basic frame with alternating bits.
    expect_byte(8'hA5);
    send_frame(8'hA5, 1'b1);

    // Two frames with no extra idle bit between them.
    expect_byte(8'h00);
    expect_byte(8'hFF);
    send_frame(8'h00, 1'b1);
    send_frame(8'hFF, 1'b1);

    // False start: low shorter than half a bit, then return high.
    begin
      int bytes_before;
      int errors_before;
      bytes_before = expected_rd;
      errors_before = framing_errors;
      @(negedge clk);
      rx_i = 1'b0;
      repeat (2) @(posedge clk);
      @(negedge clk);
      rx_i = 1'b1;
      repeat (CLKS_PER_BIT + 6) @(posedge clk);
      if (expected_rd != bytes_before)
        fail("false start produced a byte");
      if (framing_errors != errors_before)
        fail("false start produced a framing error");
      if (busy_o !== 1'b0)
        fail("receiver did not return idle after false start");
    end

    // A low stop bit must report an error and must not report data valid.
    begin
      int bytes_before;
      int errors_before;
      bytes_before = expected_rd;
      errors_before = framing_errors;
      send_frame(8'h3C, 1'b0);
      @(negedge clk);
      rx_i = 1'b1;
      repeat (CLKS_PER_BIT + 6) @(posedge clk);
      if (expected_rd != bytes_before)
        fail("bad stop bit produced valid data");
      if (framing_errors != errors_before + 1)
        fail("bad stop bit did not produce exactly one framing error");
    end

    // Reset in the middle of a partial frame must abort it cleanly.
    send_bit(1'b0);
    send_bit(1'b1);
    @(negedge clk);
    rst_n = 1'b0;
    rx_i = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    repeat (3) @(posedge clk);
    if (busy_o !== 1'b0 || valid_o !== 1'b0)
      fail("mid-frame reset did not return receiver to idle");

    // Random regression frames.
    for (int i = 0; i < 20; i++) begin
      logic [7:0] random_byte;
      random_byte = $urandom_range(255);
      expect_byte(random_byte);
      send_frame(random_byte, 1'b1);
    end

    @(negedge clk);
    rx_i = 1'b1;
    repeat (CLKS_PER_BIT + 6) @(posedge clk);

    if (expected_rd != expected_wr) begin
      $display("FAIL UART scoreboard expected=%0d received=%0d",
               expected_wr, expected_rd);
      errors++;
    end

    if (errors == 0)
      $display("PASS p10_uart_rx");
    else
      $fatal(1, "FAIL p10_uart_rx errors=%0d", errors);

    $finish;
  end
endmodule

