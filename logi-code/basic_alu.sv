module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] a_plus_b,
    output logic [31:0] a_minus_b,
    output logic [31:0] not_a,
    output logic [31:0] a_and_b,
    output logic [31:0] a_or_b,
    output logic [31:0] a_xor_b
);
    assign a_and_b = a & b;
    assign a_minus_b = a - b;
    assign a_or_b = a | b;
    assign a_plus_b = a + b;
    assign a_xor_b = a ^ b;
    assign not_a = ~a;
endmodule