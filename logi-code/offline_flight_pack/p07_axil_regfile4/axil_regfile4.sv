`timescale 1ns/1ps

module axil_regfile4 #(
    parameter int ADDR_W = 4,
    parameter int DATA_W = 32,
    parameter int STRB_W = DATA_W / 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [ADDR_W-1:0]     s_awaddr,
    input  logic                  s_awvalid,
    output logic                  s_awready,
    input  logic [DATA_W-1:0]     s_wdata,
    input  logic [STRB_W-1:0]     s_wstrb,
    input  logic                  s_wvalid,
    output logic                  s_wready,
    output logic [1:0]            s_bresp,
    output logic                  s_bvalid,
    input  logic                  s_bready,
    input  logic [ADDR_W-1:0]     s_araddr,
    input  logic                  s_arvalid,
    output logic                  s_arready,
    output logic [DATA_W-1:0]     s_rdata,
    output logic [1:0]            s_rresp,
    output logic                  s_rvalid,
    input  logic                  s_rready
);

    logic aw_pending;
    logic w_pending;
    logic [ADDR_W-1:0] awaddr_q;
    logic [DATA_W-1:0] wdata_q;
    logic [STRB_W-1:0] wstrb_q;
    logic [DATA_W-1:0] regs [0:3];

    logic aw_fire;
    logic w_fire;
    logic b_fire;
    logic ar_fire;
    logic r_fire;
    logic do_write;

    logic [ADDR_W-1:0] write_addr;
    logic [DATA_W-1:0] write_data;
    logic [STRB_W-1:0] write_strb;

    always_comb begin
        s_awready = !aw_pending && !s_bvalid;
        s_wready  = !w_pending  && !s_bvalid;
        s_arready = !s_rvalid;

        s_bresp = 2'b00;
        s_rresp = 2'b00;

        aw_fire = s_awvalid && s_awready;
        w_fire  = s_wvalid  && s_wready;
        b_fire  = s_bvalid  && s_bready;
        ar_fire = s_arvalid && s_arready;
        r_fire  = s_rvalid  && s_rready;

        write_addr = aw_fire ? s_awaddr : awaddr_q;
        write_data = w_fire ? s_wdata  : wdata_q;
        write_strb = w_fire ? s_wstrb  : wstrb_q;

        do_write = !s_bvalid && (aw_pending || aw_fire) && (w_pending  || w_fire);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_pending <= 1'b0;
            w_pending  <= 1'b0;
            awaddr_q <= '0;
            wdata_q <= '0;
            wstrb_q <= '0;
            s_bvalid <= 1'b0;
            s_rvalid <= 1'b0;
            s_rdata <= '0;
            for (int i = 0; i < 4; i++) begin
                regs[i] <= '0;
            end

        end else begin
            if (b_fire) begin
                s_bvalid <= 1'b0;
            end

            if (ar_fire) begin
                s_rdata  <= regs[s_araddr[3:2]];
                s_rvalid <= 1'b1;
            end
            if (r_fire) begin
                s_rvalid <= 1'b0;
            end

            if (aw_fire) begin
                awaddr_q <= s_awaddr;
                aw_pending <= 1'b1;
            end
            if (w_fire) begin
                wdata_q <= s_wdata;
                wstrb_q <= s_wstrb;
                w_pending <= 1'b1;
            end

            if (do_write) begin
                for (int byte_idx = 0; byte_idx < STRB_W; byte_idx++) begin
                    if (write_strb[byte_idx]) begin
                        regs[write_addr[3:2]][byte_idx*8 +: 8] <= write_data[byte_idx*8 +: 8]; //register selection is done by top 2 bits {0000, 0100, 1000, 1100}
                    end
                end

                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                s_bvalid <= 1'b1;
            end

        end
    end

endmodule
