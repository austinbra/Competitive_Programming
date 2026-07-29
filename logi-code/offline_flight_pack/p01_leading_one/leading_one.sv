`timescale 1ns/1ps

module leading_one #(
    parameter int DATA_WIDTH = 32,
    parameter int INDEX_WIDTH = $clog2(DATA_WIDTH)
) (
    input  logic [DATA_WIDTH-1:0] din,
    output logic                  valid,
    output logic [INDEX_WIDTH-1:0] index,
    output logic [DATA_WIDTH-1:0] onehot
);

    logic [DATA_WIDTH-1:0] spread;

    always_comb begin
        valid  = |din;
        index  = '0;
        onehot = '0;
        if (valid) begin
            spread = din;
            spread |= spread >> 1;
            spread |= spread >> 2;
            spread |= spread >> 4;
            spread |= spread >> 8;
            spread |= spread >> 16;
            onehot = spread & ~(spread >> 1);
            for (int i = 0; i < DATA_WIDTH; i++) begin
                if (onehot[i]) begin
                    index = i;
                end
            end
        end




    end


endmodule


