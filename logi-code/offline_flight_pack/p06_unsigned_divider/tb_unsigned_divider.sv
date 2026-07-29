`timescale 1ns/1ps

module tb;
  localparam int WIDTH = 16;

  logic clk;
  logic rst_n;
  logic start_i;
  logic [WIDTH-1:0] dividend_i;
  logic [WIDTH-1:0] divisor_i;
  logic [WIDTH-1:0] quotient_o;
  logic [WIDTH-1:0] remainder_o;
  logic busy_o;
  logic done_pulse_o;
  logic div0_o;

  int errors;

  unsigned_divider #(
      .WIDTH(WIDTH)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .start_i(start_i),
      .dividend_i(dividend_i),
      .divisor_i(divisor_i),
      .quotient_o(quotient_o),
      .remainder_o(remainder_o),
      .busy_o(busy_o),
      .done_pulse_o(done_pulse_o),
      .div0_o(div0_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic fail(input string msg);
    begin
      $display("FAIL %s", msg);
      errors++;
    end
  endtask

  task automatic reset_dut;
    begin
      rst_n = 1'b0;
      start_i = 1'b0;
      dividend_i = '0;
      divisor_i = '0;
      repeat (4) @(posedge clk);
      rst_n = 1'b1;
      @(posedge clk);
      #1;
      if (busy_o !== 1'b0) fail("busy_o must clear after reset");
      if (done_pulse_o !== 1'b0) fail("done_pulse_o must clear after reset");
      if (div0_o !== 1'b0) fail("div0_o must clear after reset");
    end
  endtask

  task automatic start_op(input logic [WIDTH-1:0] dividend, input logic [WIDTH-1:0] divisor);
    begin
      wait (busy_o === 1'b0);
      @(negedge clk);
      dividend_i = dividend;
      divisor_i = divisor;
      start_i = 1'b1;
      @(posedge clk);
      #1;
      @(negedge clk);
      start_i = 1'b0;
      dividend_i = '0;
      divisor_i = '0;
    end
  endtask

  task automatic check_div(input logic [WIDTH-1:0] dividend, input logic [WIDTH-1:0] divisor);
    int cycles;
    logic [WIDTH-1:0] exp_q;
    logic [WIDTH-1:0] exp_r;
    begin
      start_op(dividend, divisor);

      if (divisor == 0) begin
        if (done_pulse_o !== 1'b1) fail("div0 must produce immediate done_pulse_o");
        if (div0_o !== 1'b1) fail("div0_o must assert for divisor zero");
        if (busy_o !== 1'b0) fail("busy_o must stay low for divisor zero");
        if (quotient_o !== '0) fail("quotient must be zero for divisor zero");
        if (remainder_o !== '0) fail("remainder must be zero for divisor zero");
        @(posedge clk);
        #1;
        if (done_pulse_o !== 1'b0) fail("done_pulse_o must be one cycle for div0");
      end else begin
        if (done_pulse_o === 1'b1) fail("normal division should not complete on the start edge");
        if (busy_o !== 1'b1) fail("busy_o must assert for normal division");

        cycles = 0;
        while (done_pulse_o !== 1'b1) begin
          @(posedge clk);
          #1;
          cycles++;
          if (cycles > WIDTH + 6) begin
            $display("FAIL timeout dividend=%0d divisor=%0d", dividend, divisor);
            $fatal(1);
          end
        end

        exp_q = dividend / divisor;
        exp_r = dividend % divisor;

        if (div0_o !== 1'b0) fail("div0_o must be low for normal division");
        if (quotient_o !== exp_q) begin
          $display("FAIL quotient %0d/%0d got=%0d exp=%0d", dividend, divisor, quotient_o, exp_q);
          errors++;
        end
        if (remainder_o !== exp_r) begin
          $display("FAIL remainder %0d/%0d got=%0d exp=%0d", dividend, divisor, remainder_o, exp_r);
          errors++;
        end
        if (busy_o !== 1'b0) fail("busy_o must clear with done_pulse_o");

        @(posedge clk);
        #1;
        if (done_pulse_o !== 1'b0) fail("done_pulse_o must be exactly one cycle");
      end
    end
  endtask

  initial begin
    errors = 0;
    reset_dut();

    check_div(16'd10, 16'd3);
    check_div(16'd255, 16'd16);
    check_div(16'd0, 16'd7);
    check_div(16'd7, 16'd0);
    check_div(16'hFFFF, 16'd255);
    check_div(16'd12345, 16'd67);

    for (int i = 0; i < 30; i++) begin
      check_div($urandom_range(0, 16'hFFFF), $urandom_range(1, 16'h0FFF));
    end

    if (errors == 0) begin
      $display("PASS p06_unsigned_divider");
    end else begin
      $display("FAIL p06_unsigned_divider errors=%0d", errors);
      $fatal(1);
    end
    $finish;
  end
endmodule
