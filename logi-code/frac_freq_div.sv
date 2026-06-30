`timescale 1ns / 1ps

module freq_divbyfrac #(
    parameter int unsigned MUL2_DIV_CLK = 7
) (
    input  logic rst_n,
    input  logic clk_2x,
    output logic clk_div
);

    initial begin
        if (MUL2_DIV_CLK < 2) begin
            $fatal(1, "MUL2_DIV_CLK must be >= 2");
        end
    end

    localparam int unsigned HIGH_HALVES = MUL2_DIV_CLK / 2;
    localparam int unsigned LOW_HALVES  = MUL2_DIV_CLK - HIGH_HALVES;

    localparam int unsigned MAX_HALVES =
        (HIGH_HALVES > LOW_HALVES) ? HIGH_HALVES : LOW_HALVES;

    localparam int unsigned COUNT_W =
        (MAX_HALVES <= 1) ? 1 : $clog2(MAX_HALVES + 1);

    localparam logic [COUNT_W-1:0] HIGH_RELOAD = HIGH_HALVES - 1;
    localparam logic [COUNT_W-1:0] LOW_RELOAD  = LOW_HALVES  - 1;

    logic [COUNT_W-1:0] rem;

    always_ff @(posedge clk_2x or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 1'b0;
            rem     <= 1;        // wait one half-cycle before first rising edge
        end else if (rem == '0) begin
            clk_div <= ~clk_div;

            if (clk_div)
                rem <= LOW_RELOAD;   // old clk_div was high, entering low phase
            else
                rem <= HIGH_RELOAD;  // old clk_div was low, entering high phase
        end else begin
            rem <= rem - 1'b1;
        end
    end

endmodule