module dot_prod (
    input  logic [7:0]  din,
    input  logic        clk,
    input  logic        resetn,
    output logic [17:0] dout,
    output logic        run
);

    localparam int COUNT_W = $clog2(6);

    logic [COUNT_W-1:0] idx;
    logic [7:0] data [0:5];

    logic [17:0] prod [0:1];

    genvar i;
    generate
        for (i = 0; i < 2; i++) begin : gen_products
            assign prod[i] = 18'(data[i]) * 18'(data[i+3]);
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (!resetn) begin
            idx  <= '0;
            dout <= '0;
            run  <= 1'b1;

            for (int j = 0; j < 6; j++) begin
                data[j] <= '0;
            end
        end else begin
            data[idx] <= din;

            if (idx == 5) begin
                dout <= prod[0] +
                        prod[1] +
                        18'(data[2]) * 18'(din);

                run <= 1'b1;
                idx <= '0;
            end else begin
                run <= 1'b0;
                idx <= idx + 1'b1;
            end
        end
    end

endmodule