module async_fifo_gray #(
    parameter int DATA_W = 8,
    parameter int ADDR_W = 3
) (
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              wr_valid,
    output logic              wr_ready,
    input  logic [DATA_W-1:0] wr_data,

    input  logic              rd_clk,
    input  logic              rd_rst_n,
    output logic              rd_valid,
    input  logic              rd_ready,
    output logic [DATA_W-1:0] rd_data
);
    localparam int DEPTH = 1 << ADDR_W;

    logic [ADDR_W:0] rptr, rptr_next;
    logic [ADDR_W:0] wptr, wptr_next;

    logic [ADDR_W:0] rptr_gray, rptr_gray_next;
    logic [ADDR_W:0] wptr_gray, wptr_gray_next;

    logic r_fire, w_fire;

    logic full, full_next;
    logic empty, empty_next;

    logic [ADDR_W:0] r1, r2;
    logic [ADDR_W:0] w1, w2;

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    function automatic logic [ADDR_W:0] bin_to_gray(
        input logic [ADDR_W:0] ptr
    );
        return ptr ^ (ptr >> 1);
    endfunction

    assign wr_ready = !full;
    assign w_fire = wr_ready && wr_valid;

    assign rd_valid = !empty;
    assign r_fire = rd_ready && rd_valid;

    assign wptr_next = wptr + w_fire;
    assign rptr_next = rptr + r_fire;

    assign wptr_gray_next = bin_to_gray(wptr_next);
    assign rptr_gray_next = bin_to_gray(rptr_next);

    assign full_next = (wptr_gray_next == {~r2[ADDR_W:ADDR_W-1], r2[ADDR_W-2:0]});
    assign empty_next = (rptr_gray_next == w2);

    assign rd_data = mem[rptr[ADDR_W-1:0]];

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            r1 <= '0;
            r2 <= '0;
            wptr <= '0;
            wptr_gray <= '0;
            full <= 1'b0;
        end else begin
            r1 <= rptr_gray;
            r2 <= r1;

            wptr <= wptr_next;
            wptr_gray <= wptr_gray_next;
            full <= full_next;

            if (w_fire)
                mem[wptr[ADDR_W-1:0]] <= wr_data;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            w1 <= '0;
            w2 <= '0;
            rptr <= '0;
            rptr_gray <= '0;
            empty <= 1'b1;
        end else begin
            w1 <= wptr_gray;
            w2 <= w1;

            rptr <= rptr_next;
            rptr_gray <= rptr_gray_next;
            empty <= empty_next;
        end
    end

endmodule