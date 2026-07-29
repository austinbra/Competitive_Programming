module axi_lite_slave #(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32,
    parameter int NUM_REGS   = 4
) (
    input  logic                      clk,
    input  logic                      rst_n,

    input  logic [ADDR_WIDTH-1:0]     awaddr,
    input  logic                      awvalid,
    output logic                      awready,

    input  logic [DATA_WIDTH-1:0]     wdata,
    input  logic [DATA_WIDTH/8-1:0]   wstrb,
    input  logic                      wvalid,
    output logic                      wready,

    output logic [1:0]                bresp,
    output logic                      bvalid,
    input  logic                      bready,

    input  logic [ADDR_WIDTH-1:0]     araddr,
    input  logic                      arvalid,
    output logic                      arready,

    output logic [DATA_WIDTH-1:0]     rdata,
    output logic [1:0]                rresp,
    output logic                      rvalid,
    input  logic                      rready
);

    localparam int NUM_BYTES = DATA_WIDTH / 8;

    logic aw_fire;
    logic w_fire;
    logic b_fire;
    logic ar_fire;
    logic r_fire;

    logic aw_pend;
    logic w_pend;

    logic [ADDR_WIDTH-1:0] awaddr_q;
    logic [DATA_WIDTH-1:0] wdata_q;
    logic [NUM_BYTES-1:0]  wstrb_q;

    logic [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];

    logic [ADDR_WIDTH-1:0] sel_awaddr;
    logic [DATA_WIDTH-1:0] sel_wdata;
    logic [NUM_BYTES-1:0]  sel_wstrb;

    logic [ADDR_WIDTH-1:0] write_index;
    logic [ADDR_WIDTH-1:0] read_index;

    logic do_write;

    always_comb begin
        /*
         * Do not accept another write address/data while a previous
         * response is pend.
         */
        awready = rst_n && !aw_pend && !bvalid;
        wready  = rst_n && !w_pend && !bvalid;

        /*
         * Only one outstanding read transaction is supported.
         */
        arready = rst_n && !rvalid;

        aw_fire = awvalid && awready;
        w_fire  = wvalid  && wready;
        b_fire  = bvalid  && bready;

        ar_fire = arvalid && arready;
        r_fire  = rvalid  && rready;

        /*
         * Use the value arriving this cycle when a handshake occurs.
         * Otherwise, use the previously buffered value.
         */
        sel_awaddr = aw_fire ? awaddr : awaddr_q;
        sel_wdata  = w_fire  ? wdata  : wdata_q;
        sel_wstrb  = w_fire  ? wstrb  : wstrb_q;

        write_index = sel_awaddr / NUM_BYTES;
        read_index  = araddr / NUM_BYTES;

        /*
         * Write as soon as both channels have completed, regardless
         * of which channel arrived first.
         */
        do_write = !bvalid && (aw_pend || aw_fire) && (w_pend  || w_fire);
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            aw_pend <= 1'b0;
            w_pend  <= 1'b0;

            awaddr_q <= '0;
            wdata_q  <= '0;
            wstrb_q  <= '0;

            bvalid <= 1'b0;
            bresp  <= 2'b00;

            rvalid <= 1'b0;
            rdata  <= '0;
            rresp  <= 2'b00;

            for (int i = 0; i < NUM_REGS; i++) begin
                regs[i] <= '0;
            end
        end else begin
            /*
             * Capture AW and W independently because AXI-Lite permits
             * them to arrive in either order.
             */
            if (aw_fire) begin
                aw_pend <= 1'b1;
                awaddr_q   <= awaddr;
            end

            if (w_fire) begin
                w_pend <= 1'b1;
                wdata_q   <= wdata;
                wstrb_q   <= wstrb;
            end

            /*
             * Complete the current B-channel transaction.
             */
            if (b_fire) begin
                bvalid <= 1'b0;
                bresp  <= 2'b00;
            end

            /*
             * A write begins once both AW and W have been received.
             */
            if (do_write) begin
                bvalid <= 1'b1;

                if (write_index < NUM_REGS) begin
                    bresp <= 2'b00;

                    for (int byte_idx = 0; byte_idx < NUM_BYTES; byte_idx++) begin

                        if (sel_wstrb[byte_idx]) begin
                            regs[write_index][byte_idx*8 +: 8]
                                <= sel_wdata[byte_idx*8 +: 8];
                        end
                    end
                end else begin
                    bresp <= 2'b10;
                end

                aw_pend <= 1'b0;
                w_pend  <= 1'b0;
            end

            /*
             * Complete the current R-channel transaction.
             */
            if (r_fire) begin
                rvalid <= 1'b0;
                rresp  <= 2'b00;
            end

            /*
             * Produce a registered read response after the AR
             * handshake.
             */
            if (ar_fire) begin
                rvalid <= 1'b1;

                if (read_index < NUM_REGS) begin
                    rdata <= regs[read_index];
                    rresp <= 2'b00;
                end else begin
                    rdata <= '0;
                    rresp <= 2'b10;
                end
            end
        end
    end

endmodule
