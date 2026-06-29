timeunit 1ns; timeprecision 1ps;

module skip3 (
    input logic clk,
    input logic rst,

    input logic valid_in,
    input logic signed [31:0] value_in,

    output logic valid_out,
    output logic signed [31:0] value_out
);
    logic [1:0] phase;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            value_out <= '0;
            phase <= 2'd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            if (phase == 2'd2) begin
                phase <= 2'd0;
                valid_out <= 1'b0;
            end else begin
                phase <= phase + 2'd1;
                valid_out <= 1'b1;
                value_out <= value_in;
            end
        end
    end

endmodule


module skip_every_3rd_bit #(
    parameter int DATA_WIDTH = 8
) (
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH - (DATA_WIDTH / 3) - 1:0] dout
);
    always_comb begin :
        int j = 0;
        for (int i = 0; i < DATA_WIDTH; i++) begin
            if (i % 3 != 0) begin
                dout[j++] = din[i];
            end
        end
    end

endmodule