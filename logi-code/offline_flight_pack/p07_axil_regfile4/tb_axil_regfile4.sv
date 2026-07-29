`timescale 1ns/1ps

module tb;
  localparam int ADDR_W = 4;
  localparam int DATA_W = 32;
  localparam int STRB_W = DATA_W / 8;

  logic clk;
  logic rst_n;
  logic [ADDR_W-1:0] s_awaddr;
  logic s_awvalid;
  logic s_awready;
  logic [DATA_W-1:0] s_wdata;
  logic [STRB_W-1:0] s_wstrb;
  logic s_wvalid;
  logic s_wready;
  logic [1:0] s_bresp;
  logic s_bvalid;
  logic s_bready;
  logic [ADDR_W-1:0] s_araddr;
  logic s_arvalid;
  logic s_arready;
  logic [DATA_W-1:0] s_rdata;
  logic [1:0] s_rresp;
  logic s_rvalid;
  logic s_rready;

  logic [DATA_W-1:0] mirror [0:3];
  int errors;

  axil_regfile4 #(
      .ADDR_W(ADDR_W),
      .DATA_W(DATA_W)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .s_awaddr(s_awaddr),
      .s_awvalid(s_awvalid),
      .s_awready(s_awready),
      .s_wdata(s_wdata),
      .s_wstrb(s_wstrb),
      .s_wvalid(s_wvalid),
      .s_wready(s_wready),
      .s_bresp(s_bresp),
      .s_bvalid(s_bvalid),
      .s_bready(s_bready),
      .s_araddr(s_araddr),
      .s_arvalid(s_arvalid),
      .s_arready(s_arready),
      .s_rdata(s_rdata),
      .s_rresp(s_rresp),
      .s_rvalid(s_rvalid),
      .s_rready(s_rready)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  function automatic int reg_index(input logic [ADDR_W-1:0] addr);
    begin
      return addr[3:2];
    end
  endfunction

  function automatic logic [DATA_W-1:0] apply_wstrb(
      input logic [DATA_W-1:0] old_value,
      input logic [DATA_W-1:0] new_value,
      input logic [STRB_W-1:0] strb
  );
    logic [DATA_W-1:0] result;
    begin
      result = old_value;
      for (int b = 0; b < STRB_W; b++) begin
        if (strb[b]) result[b*8 +: 8] = new_value[b*8 +: 8];
      end
      return result;
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
      s_awaddr = '0;
      s_awvalid = 1'b0;
      s_wdata = '0;
      s_wstrb = '0;
      s_wvalid = 1'b0;
      s_bready = 1'b0;
      s_araddr = '0;
      s_arvalid = 1'b0;
      s_rready = 1'b0;
      for (int i = 0; i < 4; i++) mirror[i] = '0;
      repeat (5) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  task automatic send_aw(input logic [ADDR_W-1:0] addr);
    int cycles;
    begin
      @(negedge clk);
      s_awaddr = addr;
      s_awvalid = 1'b1;
      cycles = 0;
      while (!(s_awvalid && s_awready)) begin
        @(posedge clk);
        #1;
        cycles++;
        if (cycles > 30) begin
          $display("FAIL AW timeout addr=%h", addr);
          errors++;
          s_awvalid = 1'b0;
          $fatal(1);
        end
      end
      @(negedge clk);
      s_awvalid = 1'b0;
      s_awaddr = '0;
    end
  endtask

  task automatic send_w(input logic [DATA_W-1:0] data, input logic [STRB_W-1:0] strb);
    int cycles;
    begin
      @(negedge clk);
      s_wdata = data;
      s_wstrb = strb;
      s_wvalid = 1'b1;
      cycles = 0;
      while (!(s_wvalid && s_wready)) begin
        @(posedge clk);
        #1;
        cycles++;
        if (cycles > 30) begin
          $display("FAIL W timeout data=%h strb=%b", data, strb);
          errors++;
          s_wvalid = 1'b0;
          $fatal(1);
        end
      end
      @(negedge clk);
      s_wvalid = 1'b0;
      s_wdata = '0;
      s_wstrb = '0;
    end
  endtask

  task automatic recv_b(input int stall_cycles);
    int cycles;
    begin
      s_bready = 1'b0;
      cycles = 0;
      while (s_bvalid !== 1'b1) begin
        @(posedge clk);
        #1;
        cycles++;
        if (cycles > 30) begin
          fail("B timeout");
          $fatal(1);
        end
      end
      if (s_bresp !== 2'b00) fail("BRESP must be OKAY");
      for (int i = 0; i < stall_cycles; i++) begin
        @(posedge clk);
        #1;
        if (s_bvalid !== 1'b1) fail("BVALID must hold while BREADY is low");
        if (s_bresp !== 2'b00) fail("BRESP must stay OKAY while stalled");
      end
      @(negedge clk);
      s_bready = 1'b1;
      @(posedge clk);
      #1;
      @(negedge clk);
      s_bready = 1'b0;
      @(posedge clk);
      #1;
      if (s_bvalid !== 1'b0) fail("BVALID must clear after BREADY handshake");
    end
  endtask

  task automatic axil_write_aw_first(
      input logic [ADDR_W-1:0] addr,
      input logic [DATA_W-1:0] data,
      input logic [STRB_W-1:0] strb,
      input int stall_b
  );
    begin
      send_aw(addr);
      repeat (2) @(posedge clk);
      send_w(data, strb);
      recv_b(stall_b);
      mirror[reg_index(addr)] = apply_wstrb(mirror[reg_index(addr)], data, strb);
    end
  endtask

  task automatic axil_write_w_first(
      input logic [ADDR_W-1:0] addr,
      input logic [DATA_W-1:0] data,
      input logic [STRB_W-1:0] strb,
      input int stall_b
  );
    begin
      send_w(data, strb);
      repeat (2) @(posedge clk);
      send_aw(addr);
      recv_b(stall_b);
      mirror[reg_index(addr)] = apply_wstrb(mirror[reg_index(addr)], data, strb);
    end
  endtask

  task automatic axil_read(
      input logic [ADDR_W-1:0] addr,
      input int stall_r
  );
    int cycles;
    logic [DATA_W-1:0] stable_data;
    logic [DATA_W-1:0] expected;
    begin
      expected = mirror[reg_index(addr)];
      @(negedge clk);
      s_araddr = addr;
      s_arvalid = 1'b1;
      s_rready = 1'b0;
      cycles = 0;
      while (!(s_arvalid && s_arready)) begin
        @(posedge clk);
        #1;
        cycles++;
        if (cycles > 30) begin
          $display("FAIL AR timeout addr=%h", addr);
          errors++;
          s_arvalid = 1'b0;
          $fatal(1);
        end
      end
      @(negedge clk);
      s_arvalid = 1'b0;
      s_araddr = '0;

      cycles = 0;
      while (s_rvalid !== 1'b1) begin
        @(posedge clk);
        #1;
        cycles++;
        if (cycles > 30) begin
          $display("FAIL R timeout addr=%h", addr);
          errors++;
          $fatal(1);
        end
      end

      if (s_rresp !== 2'b00) fail("RRESP must be OKAY");
      stable_data = s_rdata;
      for (int i = 0; i < stall_r; i++) begin
        @(posedge clk);
        #1;
        if (s_rvalid !== 1'b1) fail("RVALID must hold while RREADY is low");
        if (s_rdata !== stable_data) fail("RDATA must remain stable while stalled");
      end

      if (s_rdata !== expected) begin
        $display("FAIL read addr=%h got=%h exp=%h", addr, s_rdata, expected);
        errors++;
      end

      @(negedge clk);
      s_rready = 1'b1;
      @(posedge clk);
      #1;
      @(negedge clk);
      s_rready = 1'b0;
      @(posedge clk);
      #1;
      if (s_rvalid !== 1'b0) fail("RVALID must clear after RREADY handshake");
    end
  endtask

  initial begin
    errors = 0;
    reset_dut();

    axil_write_aw_first(4'h0, 32'h1111_2222, 4'b1111, 0);
    axil_write_aw_first(4'h4, 32'h3333_4444, 4'b1111, 2);
    axil_write_w_first (4'h8, 32'h5555_6666, 4'b1111, 0);
    axil_write_w_first (4'hC, 32'h7777_8888, 4'b1111, 1);

    axil_read(4'h0, 0);
    axil_read(4'h4, 2);
    axil_read(4'h8, 0);
    axil_read(4'hC, 3);

    axil_write_aw_first(4'h4, 32'hAAAA_BBBB, 4'b0101, 0);
    axil_read(4'h4, 0);

    axil_write_w_first(4'h0, 32'hDEAD_BEEF, 4'b1010, 3);
    axil_read(4'h0, 2);

    if (errors == 0) begin
      $display("PASS p07_axil_regfile4");
    end else begin
      $display("FAIL p07_axil_regfile4 errors=%0d", errors);
      $fatal(1);
    end
    $finish;
  end
endmodule




