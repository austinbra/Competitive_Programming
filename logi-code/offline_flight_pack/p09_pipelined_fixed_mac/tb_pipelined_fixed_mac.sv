`timescale 1ns/1ps

module tb;
  localparam int DATA_W = 8;
  localparam int FRAC_W = 3;

  logic clk = 1'b0;
  logic rst_n;
  logic valid_i;
  logic signed [DATA_W-1:0] a_i;
  logic signed [DATA_W-1:0] b_i;
  logic signed [DATA_W-1:0] c_i;
  logic valid_o;
  logic signed [DATA_W-1:0] y_o;

  logic signed [DATA_W-1:0] expected [0:255];
  int accepted_cycle [0:255];
  int expected_wr;
  int expected_rd;
  int cycle_count;
  int errors;

  always #5 clk = ~clk;

  pipelined_fixed_mac #(
      .DATA_W(DATA_W),
      .FRAC_W(FRAC_W)
  ) dut (.*);

  task automatic fail(input string msg);
    begin
      $display("FAIL %s", msg);
      errors++;
    end
  endtask

  function automatic integer golden_mac(
      input integer a,
      input integer b,
      input integer c
  );
    integer raw;
    integer rounded;
    integer bias;
    integer max_value;
    integer min_value;
    begin
      // a*b has 2*FRAC_W fractional bits. Shift c so it has the same scale.
      raw = a * b + c * (1 << FRAC_W);
      bias = 1 << (FRAC_W - 1);

      // Round to nearest with exact half cases moving away from zero.
      if (raw >= 0)
        rounded = (raw + bias) >>> FRAC_W;
      else
        rounded = -(((-raw) + bias) >>> FRAC_W);

      max_value = (1 << (DATA_W - 1)) - 1;
      min_value = -(1 << (DATA_W - 1));

      if (rounded > max_value)
        golden_mac = max_value;
      else if (rounded < min_value)
        golden_mac = min_value;
      else
        golden_mac = rounded;
    end
  endfunction

  // Record accepted inputs before NBA updates, then check outputs after them.
  always @(posedge clk) begin
    cycle_count++;

    if (rst_n && valid_i) begin
      expected[expected_wr] = golden_mac($signed(a_i), $signed(b_i), $signed(c_i));
      accepted_cycle[expected_wr] = cycle_count;
      expected_wr++;
    end

    #1;
    if (rst_n && valid_o) begin
      if (expected_rd >= expected_wr) begin
        fail("valid_o asserted without a corresponding accepted input");
      end else begin
        if (y_o !== expected[expected_rd]) begin
          $display("FAIL MAC index=%0d got=%0d expected=%0d",
                   expected_rd, $signed(y_o), $signed(expected[expected_rd]));
          errors++;
        end
        if ((cycle_count - accepted_cycle[expected_rd]) != 2) begin
          $display("FAIL latency index=%0d got=%0d cycles expected=2",
                   expected_rd, cycle_count - accepted_cycle[expected_rd]);
          errors++;
        end
      end
      expected_rd++;
    end
  end

  task automatic drive(
      input logic v,
      input integer a,
      input integer b,
      input integer c
  );
    begin
      @(negedge clk);
      valid_i = v;
      a_i = a;
      b_i = b;
      c_i = c;
    end
  endtask

  initial begin
    #30000;
    $fatal(1, "FAIL timeout in p09_pipelined_fixed_mac");
  end

  initial begin
    errors = 0;
    expected_wr = 0;
    expected_rd = 0;
    cycle_count = 0;
    rst_n = 1'b0;
    valid_i = 1'b0;
    a_i = '0;
    b_i = '0;
    c_i = '0;

    repeat (4) @(posedge clk);
    drive(1'b0, 0, 0, 0);
    rst_n = 1'b1;

    // Encoded Q4.3 examples: 8 means 1.0, 4 means 0.5.
    drive(1'b1,   8,  16,   4);  // 1.0*2.0 + 0.5 = 2.5 -> 20
    drive(1'b1,  -8,  16,   4);  // -1.0*2.0 + 0.5 = -1.5 -> -12
    drive(1'b1,   1,   4,   0);  // +half-LSB tie rounds away to +1
    drive(1'b1,  -1,   4,   0);  // -half-LSB tie rounds away to -1
    drive(1'b0,   0,   0,   0);  // Bubble must propagate through valid only.
    drive(1'b1, 127, 127, 127);  // Positive saturation.
    drive(1'b1,-128, 127,-128);  // Negative saturation.
    drive(1'b1,   0,  99, -17);  // a*b is zero, output c exactly.

    // Consecutive random inputs test initiation interval = 1.
    for (int i = 0; i < 60; i++) begin
      drive(1'b1,
            $urandom_range(255) - 128,
            $urandom_range(255) - 128,
            $urandom_range(255) - 128);
    end

    // Gaps test valid/data alignment rather than only arithmetic.
    for (int i = 0; i < 20; i++) begin
      drive((i % 3) != 1,
            $urandom_range(255) - 128,
            $urandom_range(255) - 128,
            $urandom_range(255) - 128);
    end

    drive(1'b0, 0, 0, 0);
    repeat (6) @(posedge clk);
    #1;

    if (expected_rd != expected_wr) begin
      $display("FAIL pipeline did not drain accepted=%0d produced=%0d",
               expected_wr, expected_rd);
      errors++;
    end

    if (errors == 0)
      $display("PASS p09_pipelined_fixed_mac");
    else
      $fatal(1, "FAIL p09_pipelined_fixed_mac errors=%0d", errors);

    $finish;
  end
endmodule

