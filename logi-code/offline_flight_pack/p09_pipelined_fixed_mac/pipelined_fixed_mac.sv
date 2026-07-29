module pipelined_fixed_mac #(
    parameter int DATA_W = 8,
    parameter int FRAC_W = 3
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     valid_i,
    input  logic signed [DATA_W-1:0] a_i,
    input  logic signed [DATA_W-1:0] b_i,
    input  logic signed [DATA_W-1:0] c_i,
    output logic                     valid_o,
    output logic signed [DATA_W-1:0] y_o
);
    localparam int PROD_W = DATA_W << 1;
    localparam int ACC_W  = PROD_W + 1;

    logic signed [ACC_W-1:0] rounded;

    logic signed [ACC_W-1:0] acc;
    logic valid_q [0:1];

    function automatic logic signed [ACC_W-1:0] mac_acc(
        input logic signed [DATA_W-1:0] a,
        input logic signed [DATA_W-1:0] b,
        input logic signed [DATA_W-1:0] c
    );
        logic signed [PROD_W-1:0] product;
        logic signed [ACC_W-1:0] c_scaled;

        product  = a * b;
        c_scaled = c;
        c_scaled = c_scaled <<< FRAC_W;

        return product + c_scaled;
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= '0;
            y_o <= '0;
            valid_q[1] <= '0;
            valid_q[2] <= '0;
            rounded <= '0;
            acc <= '0;
        end else begin
            y_o <= '0;
            valid_q[0] <= valid_i;
            valid_q[1] <= valid_q[0];

            if (valid_i) begin
                acc <= mac_acc(a_i, b_i, c_i);
            end

            if (valid_q[0]) begin
                rounded <= (acc >= 0) ? ((acc + (1 << (FRAC_W - 1))) >>> FRAC_W) : -(((-acc) + (1 << (FRAC_W - 1))) >>> FRAC_W);
            end

            if (valid_q[1]) begin
                if (rounded > $signed(127)) begin
                    y_o <= $signed(127);
                end else if (rounded < $signed(-128)) begin
                    y_o <= $signed(-128);
                end else begin
                    y_o <= rounded[DATA_W-1:0];
                end
            end

            valid_o <= valid_q[1];
        end
    end
endmodule
