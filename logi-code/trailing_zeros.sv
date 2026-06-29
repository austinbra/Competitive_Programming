module trailing_zeros #(
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0] din,
    output logic [$clog2(DATA_WIDTH):0] dout
);
    logic [$clog2(DATA_WIDTH):0] lsb_pos;
    logic [$clog2(DATA_WIDTH):0] i;
    
    logic flag;
    always_comb begin
        lsb_pos = DATA_WIDTH;
        flag = 1'b0;
        for (int i = 0; i < DATA_WIDTH; i++) begin
            if (!flag && din[i]) begin
                lsb_pos = i;
                flag = 1'b1;
            end
        end
        dout = lsb_pos;
    end
endmodule