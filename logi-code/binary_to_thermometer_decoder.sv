module bin_to_thermo #(
    parameter DIN_WIDTH = 8
) (
    input  logic [DIN_WIDTH-1:0]    din,
    output logic [2**DIN_WIDTH-1:0] dout
);
    localparam int DOUT_WIDTH = $bits(dout); // 2**DIN_WIDTH = 256
    logic [$clog2(DOUT_WIDTH):0] shamt;

    assign shamt = DOUT_WIDTH - din - 1;
    assign dout = {DOUT_WIDTH{1'b1}} >> shamt;
    

endmodule