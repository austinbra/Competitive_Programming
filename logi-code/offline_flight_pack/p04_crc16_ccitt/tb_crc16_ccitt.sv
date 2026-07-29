`timescale 1ns/1ps

module tb;
  localparam logic [15:0] POLY = 16'h1021;
  localparam logic [15:0] INIT = 16'hFFFF;

  logic clk;
  logic rst_n;
  logic clear_i;
  logic valid_i;
  logic [7:0] data_i;
  logic [15:0] crc_o;

  logic [15:0] expected_crc;
  int errors;

  crc16_ccitt #(
      .POLY(POLY),
      .INIT(INIT)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .clear_i(clear_i),
      .valid_i(valid_i),
      .data_i(data_i),
      .crc_o(crc_o)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  function automatic logic [15:0] ref_next_crc(
      input logic [15:0] crc,
      input logic [7:0] data
  );
    logic [15:0] c;
    begin
      c = crc ^ ({data, 8'h00});
      for (int i = 0; i < 8; i++) begin
        if (c[15]) c = (c << 1) ^ POLY;
        else c = (c << 1);
      end
      return c;
    end
  endfunction

  task automatic fail(input string msg);
    begin
      $display("FAIL %s", msg);
      errors++;
    end
  endtask

  task automatic check_crc(input logic [15:0] exp, input string label_text);
    begin
      #1;
      if (crc_o !== exp) begin
        $display("FAIL %s crc_o got=%h exp=%h", label_text, crc_o, exp);
        errors++;
      end
    end
  endtask

  task automatic reset_dut;
    begin
      rst_n = 1'b0;
      clear_i = 1'b0;
      valid_i = 1'b0;
      data_i = '0;
      expected_crc = INIT;
      repeat (4) @(posedge clk);
      rst_n = 1'b1;
      @(posedge clk);
      check_crc(INIT, "after reset");
    end
  endtask

  task automatic send_byte(input logic [7:0] value);
    begin
      @(negedge clk);
      data_i = value;
      valid_i = 1'b1;
      clear_i = 1'b0;
      expected_crc = ref_next_crc(expected_crc, value);
      @(posedge clk);
      check_crc(expected_crc, "after byte");
      @(negedge clk);
      valid_i = 1'b0;
      data_i = '0;
    end
  endtask

  task automatic clear_crc;
    begin
      @(negedge clk);
      clear_i = 1'b1;
      valid_i = 1'b1;
      data_i = 8'hFF;
      expected_crc = INIT;
      @(posedge clk);
      check_crc(INIT, "after clear priority");
      @(negedge clk);
      clear_i = 1'b0;
      valid_i = 1'b0;
      data_i = '0;
    end
  endtask

  initial begin
    errors = 0;
    reset_dut();

    send_byte("1");
    send_byte("2");
    send_byte("3");
    send_byte("4");
    send_byte("5");
    send_byte("6");
    send_byte("7");
    send_byte("8");
    send_byte("9");
    check_crc(16'h29B1, "known check 123456789");

    clear_crc();
    send_byte(8'h00);
    send_byte(8'hFF);
    send_byte(8'hA5);
    send_byte(8'h5A);

    for (int i = 0; i < 20; i++) begin
      send_byte($urandom_range(0, 255));
    end

    if (errors == 0) begin
      $display("PASS p04_crc16_ccitt");
    end else begin
      $display("FAIL p04_crc16_ccitt errors=%0d", errors);
      $fatal(1);
    end
    $finish;
  end
endmodule
