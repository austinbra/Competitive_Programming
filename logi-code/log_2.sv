module log2_int (
    input  logic signed [15:0] in_0,
    output logic signed [ 7:0] out
);
  always_comb begin
    if (in_0 <= 0) out = 0;
    else if (in_0[15]) out = 15;
    else if (in_0[14]) out = 14;
    else if (in_0[13]) out = 13;
    else if (in_0[12]) out = 12;
    else if (in_0[11]) out = 11;
    else if (in_0[10]) out = 10;
    else if (in_0[9]) out = 9;
    else if (in_0[8]) out = 8;
    else if (in_0[7]) out = 7;
    else if (in_0[6]) out = 6;
    else if (in_0[5]) out = 5;
    else if (in_0[4]) out = 4;
    else if (in_0[3]) out = 3;
    else if (in_0[2]) out = 2;
    else if (in_0[1]) out = 1;
    else out = 0;
  end

endmodule