module bubble_sort #(
    parameter int BITWIDTH = 3
) (
    input  logic                  [BITWIDTH-1:0] din,
    input  logic                                 sortit,
    input  logic                                 clk,
    input  logic                                 resetn,
    output logic                  [8*BITWIDTH:0] dout
);

    logic [8*BITWIDTH:0] sorted;

    logic [BITWIDTH-1:0] bank    [0:7];
    logic [BITWIDTH-1:0] sorting [0:7];

    logic [2:0] idx;

    always_comb begin
        for (int i = 0; i < 8; i++) begin
            sorting[i] = bank[i];
        end

        for (int pass = 0; pass < 7; pass++) begin
            for (int j = 0; j < 7-pass; j++) begin
                if (sorting[j] > sorting[j+1]) begin
                    {sorting[j], sorting[j+1]} = {sorting[j+1], sorting[j]};
                end
            end
        end

        // MSB chunk = smallest, LSB chunk = largest.
        sorted = {
            1'b0,
            sorting[0],
            sorting[1],
            sorting[2],
            sorting[3],
            sorting[4],
            sorting[5],
            sorting[6],
            sorting[7]
        };
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            dout <= '0;
            idx  <= '0;

            for (int i = 0; i < 8; i++) begin
                bank[i] <= '0;
            end
        end else if (!sortit) begin
            bank[idx] <= din;
            idx <= idx + 1'b1;
            dout <= '0;
        end else begin
            dout <= sorted;
        end
    end

endmodule