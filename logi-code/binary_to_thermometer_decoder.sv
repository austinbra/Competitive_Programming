module bin_to_thermo #(
    parameter DIN_WIDTH = 8
) (
    input  logic [DIN_WIDTH-1:0]    din,
    output logic [2**DIN_WIDTH-1:0] dout
);
    localparam int DOUT_WIDTH = $bits(dout);
    logic [31:0] shift_amt;

    assign shift_amt = DOUT_WIDTH - int'(din);
    assign dout = ({DOUT_WIDTH{1'b1}} >> shift_amt);

endmodule