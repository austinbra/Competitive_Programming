`timescale 1ns/1ps

module fir4 #(
    parameter int DATA_W = 12,
    parameter int COEFF_W = 12,
    parameter int ACC_W = DATA_W + COEFF_W + 3
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic signed [DATA_W-1:0]     sample_i,
    input  logic                         valid_i,
    input  logic signed [COEFF_W-1:0]    c0_i,
    input  logic signed [COEFF_W-1:0]    c1_i,
    input  logic signed [COEFF_W-1:0]    c2_i,
    input  logic signed [COEFF_W-1:0]    c3_i,
    output logic signed [ACC_W-1:0]      sample_o,
    output logic                         valid_o
);

    logic signed [DATA_W-1:0] x1;
    logic signed [DATA_W-1:0] x2;
    logic signed [DATA_W-1:0] x3;
    logic signed [ACC_W-1:0] acc;

    always_comb begin
        acc = ($signed(sample_i) * $signed(c0_i)) +
              ($signed(x1)       * $signed(c1_i)) +
              ($signed(x2)       * $signed(c2_i)) +
              ($signed(x3)       * $signed(c3_i));
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_o <= '0;
            valid_o  <= 1'b0;
            x1       <= '0;
            x2       <= '0;
            x3       <= '0;
        end else begin
            valid_o <= 1'b0;

            if (valid_i) begin
                sample_o <= acc;
                valid_o  <= 1'b1;
                x3       <= x2;
                x2       <= x1;
                x1       <= sample_i;
            end
        end
    end

endmodule
