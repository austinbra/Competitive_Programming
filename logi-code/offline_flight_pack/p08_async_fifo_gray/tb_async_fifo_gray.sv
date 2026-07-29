`timescale 1ns/1ps

module tb;
  localparam int DATA_W = 8;
  localparam int ADDR_W = 3;
  localparam int DEPTH  = 1 << ADDR_W;

  logic wr_clk = 1'b0;
  logic wr_rst_n;
  logic wr_valid;
  logic wr_ready;
  logic [DATA_W-1:0] wr_data;

  logic rd_clk = 1'b0;
  logic rd_rst_n;
  logic rd_valid;
  logic rd_ready;
  logic [DATA_W-1:0] rd_data;

  logic [DATA_W-1:0] expected [0:255];
  int expected_wr;
  int expected_rd;
  int errors;

  // The positive edges never coincide. This keeps the simple testbench
  // scoreboard deterministic while still exercising unrelated clocks.
  always #5 wr_clk = ~wr_clk;
  always #8 rd_clk = ~rd_clk;

  async_fifo_gray #(
      .DATA_W(DATA_W),
      .ADDR_W(ADDR_W)
  ) dut (.*);

  task automatic fail(input string msg);
    begin
      $display("FAIL %s", msg);
      errors++;
    end
  endtask

  // Record exactly what the FIFO accepts in the write domain.
  always @(posedge wr_clk) begin
    if (wr_rst_n && wr_valid && wr_ready) begin
      expected[expected_wr] = wr_data;
      expected_wr++;
    end
  end

  // Compare exactly what the FIFO transfers in the read domain.
  always @(posedge rd_clk) begin
    if (rd_rst_n && rd_valid && rd_ready) begin
      if (expected_rd >= expected_wr) begin
        fail("read transfer occurred without queued data");
      end else if (rd_data !== expected[expected_rd]) begin
        $display("FAIL FIFO order index=%0d got=%02h expected=%02h",
                 expected_rd, rd_data, expected[expected_rd]);
        errors++;
      end
      expected_rd++;
    end
  end

  task automatic push(input logic [DATA_W-1:0] value);
    begin
      @(negedge wr_clk);
      wr_data  = value;
      wr_valid = 1'b1;
      while (wr_ready !== 1'b1)
        @(negedge wr_clk);
      @(posedge wr_clk);
      @(negedge wr_clk);
      wr_valid = 1'b0;
    end
  endtask

  task automatic pop_one;
    begin
      @(negedge rd_clk);
      rd_ready = 1'b1;
      while (rd_valid !== 1'b1)
        @(negedge rd_clk);
      @(posedge rd_clk);
      @(negedge rd_clk);
      rd_ready = 1'b0;
    end
  endtask

  initial begin
    #100000;
    $fatal(1, "FAIL timeout in p08_async_fifo_gray");
  end

  initial begin
    errors      = 0;
    expected_wr = 0;
    expected_rd = 0;
    wr_rst_n    = 1'b0;
    rd_rst_n    = 1'b0;
    wr_valid    = 1'b0;
    wr_data     = '0;
    rd_ready    = 1'b0;

    repeat (4) @(posedge wr_clk);
    repeat (4) @(posedge rd_clk);
    @(negedge wr_clk);
    wr_rst_n = 1'b1;
    @(negedge rd_clk);
    rd_rst_n = 1'b1;

    // Fill the FIFO completely without reading.
    for (int i = 0; i < DEPTH; i++)
      push(DATA_W'(8'h10 + i));

    @(negedge wr_clk);
    if (wr_ready !== 1'b0)
      fail("wr_ready must deassert when the FIFO is full");

    // Free three slots, then wrap the write pointer through them.
    repeat (3) pop_one();
    push(8'h20);
    push(8'h21);
    push(8'h22);

    // Drain the remaining eight entries and verify order across wrap.
    repeat (DEPTH) pop_one();

    // Wait for the empty state to settle in the read domain.
    repeat (3) @(posedge rd_clk);
    if (rd_valid !== 1'b0)
      fail("rd_valid must deassert when the FIFO is empty");

    // Concurrent traffic with deliberate, unrelated stalls.
    fork
      begin : producer
        for (int i = 0; i < 24; i++) begin
          repeat (i % 3) @(posedge wr_clk);
          push(DATA_W'(8'h80 + i));
        end
      end
      begin : consumer
        for (int i = 0; i < 24; i++) begin
          repeat ((i + 1) % 4) @(posedge rd_clk);
          pop_one();
        end
      end
    join

    repeat (4) @(posedge rd_clk);

    if (expected_rd != expected_wr) begin
      $display("FAIL scoreboard not empty writes=%0d reads=%0d",
               expected_wr, expected_rd);
      errors++;
    end

    if (errors == 0)
      $display("PASS p08_async_fifo_gray");
    else
      $fatal(1, "FAIL p08_async_fifo_gray errors=%0d", errors);

    $finish;
  end
endmodule

