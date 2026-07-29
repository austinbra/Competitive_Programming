module ping_pong_buffer #(
    parameter DATA_W = 8,
    parameter DEPTH  = 4
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 wr_en,
    input  logic [DATA_W-1:0]    wr_data,
    output logic                 wr_ready,
    input  logic                 rd_en,
    output logic [DATA_W-1:0]    rd_data,
    output logic                 rd_valid,
    output logic                 bank_sel
);

    localparam int PTR_W = $clog2(DEPTH + 1);

    // Each bank has DEPTH real entries plus one dummy entry at index DEPTH.
    //
    // Real data:  bank[x][0] through bank[x][DEPTH-1]
    // Dummy data: bank[x][DEPTH]
    //
    // rd_ptr == DEPTH means the read bank is empty. the dummy slot makes that empty pointer a
    // legal memory index. 
    logic [DATA_W-1:0] bank [0:1][0:DEPTH];

    logic [PTR_W-1:0] wr_ptr;   // 0..DEPTH, DEPTH means write bank full
    logic [PTR_W-1:0] rd_ptr;   // 0..DEPTH, DEPTH means read bank empty

    assign wr_ready = (wr_ptr < DEPTH);
    assign rd_valid = (rd_ptr < DEPTH);

    assign rd_data = bank[~bank_sel][rd_ptr];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr   <= '0;
            rd_ptr   <= DEPTH;
            bank_sel <= 1'b0;

        end else begin

            if (wr_en && wr_ready) begin
                bank[bank_sel][wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end

            if (rd_en && rd_valid) begin
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Swap only when the write bank was already full before this edge.
            if ((
                    (wr_ptr == DEPTH) || //set wr_ready low
                    (wr_en && rd_valid && (wr_ptr == DEPTH - 1)) //if curr edge is last
                )
                &&
                (
                    (rd_ptr == DEPTH) || //set rd_ready low
                    (rd_en && rd_valid && (rd_ptr == DEPTH - 1)) //if curr edge is last
                )
            ) begin
                bank_sel <= ~bank_sel;
                wr_ptr   <= '0;
                rd_ptr   <= '0;
            end
        end
    end

endmodule