`timescale 1ns/1ps

module unsigned_divider #(
    parameter int WIDTH = 16
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start_i,
    input  logic [WIDTH-1:0] dividend_i,
    input  logic [WIDTH-1:0] divisor_i,
    output logic [WIDTH-1:0] quotient_o,
    output logic [WIDTH-1:0] remainder_o,
    output logic             busy_o,
    output logic             done_pulse_o,
    output logic             div0_o
);

    localparam int COUNT_W = $clog2(WIDTH + 1);

    logic [WIDTH-1:0] dividend_q;
    logic [WIDTH-1:0] divisor_q;
    logic [WIDTH-1:0] quotient_q;
    logic [WIDTH:0] remainder_q;
    logic [COUNT_W-1:0] count_q;

    logic [WIDTH:0] shifted_remainder;
    logic [WIDTH:0] sub_remainder;
    logic           can_subtract;

    always_comb begin
        shifted_remainder = {remainder_q[WIDTH-1:0], dividend_q[WIDTH-1]};
        sub_remainder = shifted_remainder - {1'b0, divisor_q};
        can_subtract = shifted_remainder >= {1'b0, divisor_q};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_o    <= '0;
            remainder_o   <= '0;
            busy_o        <= 1'b0;
            done_pulse_o  <= 1'b0;
            div0_o        <= 1'b0;
            dividend_q    <= '0;
            divisor_q     <= '0;
            quotient_q    <= '0;
            remainder_q   <= '0;
            count_q       <= '0;
        end else begin
            done_pulse_o <= 1'b0;
            div0_o       <= 1'b0;

            if (start_i && !busy_o) begin
                quotient_o  <= '0;
                remainder_o <= '0;
                dividend_q  <= dividend_i;
                divisor_q   <= divisor_i;
                quotient_q  <= '0;
                remainder_q <= '0;
                count_q     <= WIDTH;

                if (divisor_i == '0) begin
                    div0_o <= 1'b1;
                    done_pulse_o <= 1'b1;
                    busy_o <= 1'b0;
                end else begin
                    busy_o <= 1'b1;
                end
            end else if (busy_o) begin
                dividend_q <= dividend_q << 1;

                if (can_subtract) begin
                    remainder_q <= sub_remainder;
                    quotient_q  <= {quotient_q[WIDTH-2:0], 1'b1};
                end else begin
                    remainder_q <= shifted_remainder;
                    quotient_q  <= {quotient_q[WIDTH-2:0], 1'b0};
                end

                if (count_q == 1) begin
                    busy_o       <= 1'b0;
                    done_pulse_o <= 1'b1;
                    quotient_o   <= {quotient_q[WIDTH-2:0], can_subtract};

                    if (can_subtract) begin
                        remainder_o <= sub_remainder[WIDTH-1:0];
                    end else begin
                        remainder_o <= shifted_remainder[WIDTH-1:0];
                    end

                    count_q <= '0;
                end else begin
                    count_q <= count_q - 1'b1;
                end
            end
        end
    end

endmodule
