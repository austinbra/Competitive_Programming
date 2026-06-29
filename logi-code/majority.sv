module majority (
    input  logic a,
    b,
    c,
    output logic out
);
  assign out = (a && b) || (a && c) || (b && c);
endmodule