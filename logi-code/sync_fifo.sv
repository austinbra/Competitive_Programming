module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8
) (
    input  logic                    clk,
    input  logic                    resetn,
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    full,
    output logic                    empty,
    output logic [$clog2(DEPTH+1)-1:0] count
);

    localparam PTR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] data [0:DEPTH-1];
    logic [PTR_W-1:0] wr_ptr, rd_ptr;

    assign full = (count == DEPTH);
    assign empty = (count == 0);

    function automatic logic [PTR_W-1:0] ptr_inc(input logic [PTR_W-1:0] ptr);
        if (ptr == DEPTH-1)
            ptr_inc = '0;
        else
            ptr_inc = ptr + 1'b1;
    endfunction

    always_ff @(posedge clk) begin
        if (!resetn) begin
            count <= '0;
            wr_ptr <= '0;
            rd_ptr <= '0;
            rd_data <= '0;
        end else begin
            if (rd_en && wr_en && !empty && !full) begin
                rd_data <= data[rd_ptr];
                data[wr_ptr] <= wr_data;
                rd_ptr <= ptr_inc(rd_ptr);
                wr_ptr <= ptr_inc(wr_ptr);
                count <= count;
            end

            else if (rd_en && !empty) begin
                rd_data <= data[rd_ptr];
                rd_ptr <= ptr_inc(rd_ptr);
                count <= count - 1'b1;
            end

            else if (wr_en && !full) begin
                data[wr_ptr] <= wr_data;
                wr_ptr <= ptr_inc(wr_ptr);
                count <= count + 1'b1;
            end
        end
    end

endmodule