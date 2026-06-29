module piso_shift_reg #(
    parameter DATA_WIDTH = 32
    localparam int COUNT_WIDTH = $clog2(DATA_WIDTH + 1)
) (
    input logic clk,
    input logic resetn,
    input logic [DATA_WIDTH-1:0] din,
    input logic din_en,
    output logic dout
);  

    logic [$clog2(DATA_WIDTH + 1)-1:0] bits_left;
    logic [DATA_WIDTH-1:0] curr;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            bits_left <= '0;
            curr      <= '0;
            dout      <= 1'b0;
        end else if (din_en) begin
            dout      <= din[0];
            curr      <= din >> 1;
            bits_left <= COUNT_WIDTH'(DATA_WIDTH - 1);
        end else if (bits_left != '0) begin
            dout      <= curr[0];
            curr      <= curr >> 1;
            bits_left <= bits_left - 1'b1;
        end else begin
            dout      <= 1'b0;
        end
    end
endmodule