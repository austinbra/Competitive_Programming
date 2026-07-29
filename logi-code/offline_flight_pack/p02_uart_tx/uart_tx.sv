`timescale 1ns/1ps

module uart_tx #(
    parameter int CLKS_PER_BIT = 16
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] data_i,
    input  logic       valid_s,
    output logic       ready_s,
    output logic       tx_o,
    output logic       busy_o,
    output logic       done_pulse_o
);

    localparam int CLK_W = $clog2(CLKS_PER_BIT);

    // frame[0] is start, frame[1:8] are data bits (LSB first), and
    // frame[9] is the stop bit.
    logic [9:0] frame;
    logic [3:0] bit_idx;
    logic [CLK_W-1:0] clk_count;

    assign ready_s = !busy_o;
    assign tx_o = busy_o ? frame[bit_idx] : 1'b1;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            busy_o <= 1'b0;
            done_pulse_o <= 1'b0;
            frame <= '1;
            bit_idx <= '0;
            clk_count <= '0;
        end else begin
            done_pulse_o <= 1'b0;

            if (!busy_o && valid_s) begin
                frame <= {1'b1, data_i, 1'b0};
                busy_o <= 1'b1;
                bit_idx <= '0;
                clk_count <= '0;
            end else if (clk_count == CLKS_PER_BIT - 1) begin
                clk_count <= '0;

                if (bit_idx == 4'd9) begin
                    busy_o <= 1'b0;
                    done_pulse_o <= 1'b1;
                end else begin
                    bit_idx <= bit_idx + 1'b1;
                end
            end else begin
                clk_count <= clk_count + 1'b1;
            end
        end
    end

endmodule