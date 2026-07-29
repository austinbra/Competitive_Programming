`timescale 1ns/1ps

module tb;
  localparam int DATA_WIDTH = 32;
  localparam int INDEX_WIDTH = $clog2(DATA_WIDTH);

  logic [DATA_WIDTH-1:0] din;
  logic                  valid;
  logic [INDEX_WIDTH-1:0] index;
  logic [DATA_WIDTH-1:0] onehot;

  int errors;

  leading_one #(
      .DATA_WIDTH(DATA_WIDTH),
      .INDEX_WIDTH(INDEX_WIDTH)
  ) dut (
      .din(din),
      .valid(valid),
      .index(index),
      .onehot(onehot)
  );

  function automatic int ref_index(input logic [DATA_WIDTH-1:0] value);
    int result;
    begin
      result = 0;
      for (int i = 0; i < DATA_WIDTH; i++) begin
        if (value[i]) result = i;
      end
      return result;
    end
  endfunction

  task automatic check(input logic [DATA_WIDTH-1:0] value);
    logic exp_valid;
    int exp_index;
    logic [DATA_WIDTH-1:0] exp_onehot;
    begin
      din = value;
      #1;

      exp_valid = |value;
      exp_index = exp_valid ? ref_index(value) : 0;
      exp_onehot = exp_valid ? ({{(DATA_WIDTH-1){1'b0}}, 1'b1} << exp_index) : '0;

      if (valid !== exp_valid) begin
        $display("FAIL valid din=%h got=%0b exp=%0b", value, valid, exp_valid);
        errors++;
      end

      if (index !== exp_index[INDEX_WIDTH-1:0]) begin
        $display("FAIL index din=%h got=%0d exp=%0d", value, index, exp_index);
        errors++;
      end

      if (onehot !== exp_onehot) begin
        $display("FAIL onehot din=%h got=%h exp=%h", value, onehot, exp_onehot);
        errors++;
      end
    end
  endtask

  initial begin
    errors = 0;
    din = '0;

    check(32'h0000_0000);
    check(32'h0000_0001);
    check(32'h8000_0000);
    check(32'h0000_1800);
    check(32'h0000_0800);
    check(32'h0000_1000);
    check(32'h0000_0003);
    check(32'h00F0_0001);
    check(32'h7FFF_FFFF);

    for (int i = 0; i < DATA_WIDTH; i++) begin
      check(32'h1 << i);
    end

    for (int i = 0; i < 100; i++) begin
      check($urandom());
    end

    if (errors == 0) begin
      $display("PASS p01_leading_one");
    end else begin
      $display("FAIL p01_leading_one errors=%0d", errors);
      $fatal(1);
    end
  end
endmodule
