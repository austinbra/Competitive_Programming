module mul_sel (
    input logic clk,
    sel,
    input logic [7:0] a1,
    b1,
    a2,
    b2,
    output logic [15:0] result
);
  always_ff @(posedge clk) begin
    case (sel)
        1'b1: result <= a1 * b1;
        1'b0: result <= a2 * b2;
    endcase
  end
endmodule