module barrel_shifter (
    input  logic [7:0] in,
    input  logic [2:0] ctrl,
    output logic [7:0] out
);
    logic [7:0] s1, s2;

    assign s1 = ctrl[0] ? {1'b0, in[7:1]} : in;
    assign s2 = ctrl[1] ? {2'b00, s1[7:2]} : s1;
    assign out = ctrl[2] ? {4'b0000, s2[7:4]} : s2;

endmodule