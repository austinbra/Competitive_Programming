module max_find (
    input logic clk,
    input logic rst,
    input logic [7:0] x0,
    x1,
    x2,
    x3,
    output logic [7:0] max_value
);
    logic unsigned [7:0] max_reg [0:1];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            max_value <= '0;
            max_reg[0] <= '0;
            max_reg[1] <= '0;
        end else begin
            max_reg[0] <= (x0 >= x1) ? x0 : x1;
            max_reg[1] <= (x2 >= x3) ? x2 : x3;
            max_value <= (max_reg[0] >= max_reg[1]) ? max_reg[0] : max_reg[1];
        end
    end
endmodule