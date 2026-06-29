module polynomial_5 (
    input  logic signed [ 7:0] a,
    input  logic signed [ 7:0] b,
    output logic signed [15:0] y
);
    logic [15:0] ab;
    assign ab = a*b;
    assign y = ab << 2;


endmodule