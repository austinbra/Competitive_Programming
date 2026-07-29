`timescale 1ns/1ps

module tb;
  localparam int DATA_W = 8;
  localparam int COEFF_W = 8;
  localparam int ACC_W = DATA_W + COEFF_W + 3;

  logic clk;
  logic rst_n;
  logic signed [DATA_W-1:0] sample_i;
  logic valid_i;
  logic signed [COEFF_W-1:0] c0_i, c1_i, c2_i, c3_i;
  logic signed [ACC_W-1:0] sample_o;
  logic valid_o;

  logic signed [DATA_W-1:0] d0, d1, d2;
  int errors;

  fir4 #(
      .DATA_W(DATA_W),
      .COEFF_W(COEFF_W),
      .ACC_W(ACC_W)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .sample_i(sample_i),
      .valid_i(valid_i),
      .c0_i(c0_i),
      .c1_i(c1_i),
      .c2_i(c2_i),
      .c3_i(c3_i),
      .sample_o(sample_o),
      .valid_o(valid_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  function automatic logic signed [ACC_W-1:0] ref_fir(
      input logic signed [DATA_W-1:0] x,
      input logic signed [DATA_W-1:0] x1,
      input logic signed [DATA_W-1:0] x2,
      input logic signed [DATA_W-1:0] x3
  );
    logic signed [ACC_W-1:0] result;
    begin
      result = (x  * c0_i) +
               (x1 * c1_i) +
               (x2 * c2_i) +
               (x3 * c3_i);
      return result;
    end
  endfunction

  task automatic fail(input string msg);
    begin
      $display("FAIL %s", msg);
      errors++;
    end
  endtask

  task automatic reset_model_and_dut;
    begin
      rst_n = 1'b0;
      sample_i = '0;
      valid_i = 1'b0;
      d0 = '0;
      d1 = '0;
      d2 = '0;
      repeat (4) @(posedge clk);
      rst_n = 1'b1;
      @(posedge clk);
      #1;
      if (valid_o !== 1'b0) fail("valid_o must be low after reset");
      if (sample_o !== '0) fail("sample_o must clear after reset");
    end
  endtask

  task automatic idle_cycle;
    begin
      @(negedge clk);
      valid_i = 1'b0;
      sample_i = '0;
      @(posedge clk);
      #1;
      if (valid_o !== 1'b0) fail("valid_o must be low on idle cycle");
    end
  endtask

  task automatic send_sample(input logic signed [DATA_W-1:0] value);
    logic signed [ACC_W-1:0] expected;
    begin
      expected = ref_fir(value, d0, d1, d2);
      @(negedge clk);
      sample_i = value;
      valid_i = 1'b1;
      @(posedge clk);
      #1;
      if (valid_o !== 1'b1) fail("valid_o must assert for accepted sample");
      if (sample_o !== expected) begin
        $display("FAIL sample value=%0d got=%0d exp=%0d", value, sample_o, expected);
        errors++;
      end
      d2 = d1;
      d1 = d0;
      d0 = value;
      @(negedge clk);
      valid_i = 1'b0;
      sample_i = '0;
    end
  endtask

  initial begin
    errors = 0;
    c0_i = 1; c1_i = 2; c2_i = -1; c3_i = 3;
    reset_model_and_dut();

    send_sample(1);
    send_sample(0);
    send_sample(0);
    send_sample(0);
    send_sample(0);

    idle_cycle();
    idle_cycle();

    c0_i = 1; c1_i = 1; c2_i = 1; c3_i = 1;
    reset_model_and_dut();
    send_sample(1);
    send_sample(2);
    send_sample(3);
    send_sample(4);
    send_sample(5);

    c0_i = -2; c1_i = 3; c2_i = -4; c3_i = 1;
    reset_model_and_dut();
    send_sample(-3);
    send_sample(7);
    send_sample(-8);
    send_sample(2);
    send_sample(5);

    if (errors == 0) begin
      $display("PASS p05_fir4");
    end else begin
      $display("FAIL p05_fir4 errors=%0d", errors);
      $fatal(1);
    end
    $finish;
  end
endmodule
