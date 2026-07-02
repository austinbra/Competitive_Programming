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
    // rd_ptr == DEPTH means the read bank is empty. Since rd_data is continuously
    // assigned from bank[...][rd_ptr], the dummy slot makes that empty pointer a
    // legal memory index. The dummy slot mirrors entry 0 so rd_data matches the
    // reference behavior even when rd_valid is low.
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

            for (int b = 0; b < 2; b++) begin
                for (int i = 0; i <= DEPTH; i++) begin
                    bank[b][i] <= '0;
                end
            end
        end else begin

            // Write side
            if (wr_en && wr_ready) begin
                bank[bank_sel][wr_ptr] <= wr_data;

                // Mirror the first real entry into the dummy slot.
                // The reference effectively wraps rd_ptr == DEPTH back to index 0
                // because it slices off the high pointer bit. This keeps rd_data
                // identical without slicing or guarded-read logic.
                if (wr_ptr == 0) begin
                    bank[bank_sel][DEPTH] <= wr_data;
                end

                if (wr_ptr == DEPTH - 1) begin
                    wr_ptr <= DEPTH;
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                end
            end

            // Read side
            if (rd_en && rd_valid) begin
                if (rd_ptr == DEPTH - 1) begin
                    rd_ptr <= DEPTH;
                end else begin
                    rd_ptr <= rd_ptr + 1'b1;
                end
            end

            // Swap only when the write bank was already full before this edge.
            // This matches the reference timing: the final write fills the bank,
            // then a later edge swaps once the read bank is empty or becomes empty.
            if ((
                    (wr_ptr == DEPTH) ||
                    (wr_en && rd_valid && (wr_ptr == DEPTH - 1))
                )
                &&
                (
                    (rd_ptr == DEPTH) ||
                    (rd_en && rd_valid && (rd_ptr == DEPTH - 1))
                )
            ) begin
                bank_sel <= ~bank_sel;
                wr_ptr   <= '0;
                rd_ptr   <= '0;
            end
        end
    end

endmodule