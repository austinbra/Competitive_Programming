`timescale 1ns/1ps

module tb;
  localparam int DATA_WIDTH = 8;
  localparam int CLK_DIV = 4;

  logic clk;
  logic rst_n;
  logic [DATA_WIDTH-1:0] tx_data_i;
  logic start_i;
  logic miso_i;
  logic mosi_o;
  logic sclk_o;
  logic cs_n_o;
  logic [DATA_WIDTH-1:0] rx_data_o;
  logic busy_o;
  logic done_pulse_o;

  int errors;

  spi_master_mode0 #(
      .DATA_WIDTH(DATA_WIDTH),
      .CLK_DIV(CLK_DIV)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .tx_data_i(tx_data_i),
      .start_i(start_i),
      .miso_i(miso_i),
      .mosi_o(mosi_o),
      .sclk_o(sclk_o),
      .cs_n_o(cs_n_o),
      .rx_data_o(rx_data_o),
      .busy_o(busy_o),
      .done_pulse_o(done_pulse_o)
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
      tx_data_i = '0;
      start_i = 1'b0;
      miso_i = 1'b0;
      repeat (5) @(posedge clk);
      rst_n = 1'b1;
      @(posedge clk);
      if (cs_n_o !== 1'b1) fail("cs_n_o must idle high");
      if (sclk_o !== 1'b0) fail("sclk_o must idle low for mode 0");
      if (busy_o !== 1'b0) fail("busy_o must be low after reset");
    end
  endtask

  task automatic start_transfer(input logic [DATA_WIDTH-1:0] tx_data);
    begin
      wait (busy_o === 1'b0);
      @(negedge clk);
      tx_data_i = tx_data;
      start_i = 1'b1;
      @(posedge clk);
      @(negedge clk);
      start_i = 1'b0;
    end
  endtask

  task automatic transfer_and_check(
      input logic [DATA_WIDTH-1:0] tx_data,
      input logic [DATA_WIDTH-1:0] rx_drive
  );
    begin
      start_transfer(tx_data);
      wait (cs_n_o === 1'b0);
      #1;

      if (busy_o !== 1'b1) fail("busy_o must assert during transaction");
      if (sclk_o !== 1'b0) fail("first active half-cycle must start with sclk low");
      if (mosi_o !== tx_data[DATA_WIDTH-1]) begin
        $display("FAIL first MOSI bit got=%0b exp=%0b", mosi_o, tx_data[DATA_WIDTH-1]);
        errors++;
      end

      for (int bit_idx = DATA_WIDTH-1; bit_idx >= 0; bit_idx--) begin
        miso_i = rx_drive[bit_idx];
        @(posedge sclk_o);
        #1;
        if (cs_n_o !== 1'b0) fail("cs_n_o must stay low during every sampled bit");
        if (mosi_o !== tx_data[bit_idx]) begin
          $display("FAIL MOSI bit_idx=%0d got=%0b exp=%0b", bit_idx, mosi_o, tx_data[bit_idx]);
          errors++;
        end
        if (bit_idx > 0) begin
          @(negedge sclk_o);
          #1;
          if (mosi_o !== tx_data[bit_idx-1]) begin
            $display("FAIL MOSI did not advance after falling edge next_idx=%0d got=%0b exp=%0b", bit_idx-1, mosi_o, tx_data[bit_idx-1]);
            errors++;
          end
        end
      end

      wait (done_pulse_o === 1'b1);
      if (rx_data_o !== rx_drive) begin
        $display("FAIL rx_data_o got=%h exp=%h", rx_data_o, rx_drive);
        errors++;
      end
      @(posedge clk);
      #1;
      if (done_pulse_o !== 1'b0) fail("done_pulse_o must be one cycle");
      if (busy_o !== 1'b0) fail("busy_o must clear after done");
      if (cs_n_o !== 1'b1) fail("cs_n_o must return high after done");
      if (sclk_o !== 1'b0) fail("sclk_o must return low after done");
    end
  endtask

  initial begin
    #20000;
    $display("FAIL timeout waiting for SPI behavior");
    $fatal(1);
  end

  initial begin
    errors = 0;
    reset_dut();

    transfer_and_check(8'h3C, 8'hA6);
    repeat (4) @(posedge clk);
    transfer_and_check(8'h80, 8'h01);

    if (errors == 0) begin
      $display("PASS p03_spi_master_mode0");
    end else begin
      $display("FAIL p03_spi_master_mode0 errors=%0d", errors);
      $fatal(1);
    end
    $finish;
  end
endmodule

