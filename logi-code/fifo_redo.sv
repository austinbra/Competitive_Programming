module sync_fifo #(
    parameter int DATA_W = 32,
    parameter int DEPTH  = 16,
    parameter int ADDR_W = $clog2(DEPTH)
) (
    input  logic              clk,
    input  logic              rst_n,

    input  logic              s_valid,
    output logic              s_ready,
    input  logic [DATA_W-1:0] s_data,

    output logic              m_valid,
    input  logic              m_ready,
    output logic [DATA_W-1:0] m_data,

    output logic              full,
    output logic              empty,
    output logic [ADDR_W:0]   occupancy
);
    logic [DATA_W-1:0] data [0:DEPTH-1];
    logic [ADDR_W:0] wr_ptr;
    logic [ADDR_W:0] rd_ptr;
    logic wr_fire;
    logic rd_fire;

    assign full = (occupancy == DEPTH);
    assign empty = (occupancy == '0);

    assign m_valid = !empty;
    assign rd_fire = (m_ready && m_valid);

    assign s_ready = !full || rd_fire;
    assign wr_fire = (s_ready && s_valid);

    assign m_data = data[rd_ptr];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < DEPTH; i++) begin
                data[i] <= '0;
            end
            wr_ptr <= '0;
            rd_ptr <= '0;
            occupancy <= '0;
        end else begin
            if (rd_fire) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
            end 
            if (wr_fire) begin
                data[wr_ptr] <= s_data;
                wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
            end
            case ({rd_fire, wr_fire})
                2'b10 : occupancy <= occupancy - 1'b1;
                2'b01 : occupancy <= occupancy + 1'b1;
                default : occupancy <= occupancy;
            endcase
        end
    end
endmodule

