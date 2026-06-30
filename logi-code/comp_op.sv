module comp (
    input logic [7:0] a,
    b,
    output logic greater
);
    assign greater = ($unsigned(a) > $unsigned(b));
endmodule