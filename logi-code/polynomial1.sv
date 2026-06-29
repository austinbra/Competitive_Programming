module polynomial_1 (
    input  logic signed [7:0] x,
    output logic signed [15:0] y
);
  logic signed [8:0] x_plus_1;
  assign x_plus_1 = {x[7], x} + 1'b1;
  assign y = x_plus_1 * x_plus_1;
endmodule