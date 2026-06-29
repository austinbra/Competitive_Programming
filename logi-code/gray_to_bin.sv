module gray_to_bin #(
    parameter DATA_WIDTH = 16
) (
    input  logic [DATA_WIDTH-1:0] gray,
    output logic [DATA_WIDTH-1:0] bin
);
    always_comb begin
        bin[DATA_WIDTH-1] = gray[DATA_WIDTH-1];
        for (int i = DATA_WIDTH-2; i >= 0; i--) begin
            bin[i] = bin[i+1] ^ gray[i];
        end

        /*
        for (int i = 0; i < DATA_WIDTH; i++) begin
            bin[i] = ^(gray >> i);
        end
        */
    end
endmodule
// bin -> gray
// assign gray = bin ^ (bin >> 1);