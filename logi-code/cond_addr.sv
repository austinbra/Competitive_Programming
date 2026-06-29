module cond_adder #(
    parameter bit AREA_OPT = 1'b1
) (
    input  logic        s,
    input  logic [31:0] A, B, C, D,
    output logic [32:0] Z
);

  generate
    if (AREA_OPT) begin : area_optimized
      logic [31:0] lhs, rhs;

      assign lhs = s ? A : C;
      assign rhs = s ? B : D;
      assign Z = {1'b0, lhs} + {1'b0, rhs};
    end else begin : freq_optimized
      assign Z = s ? ({1'b0, A} + {1'b0, B}) :
                   ({1'b0, C} + {1'b0, D});
    end
  endgenerate

endmodule