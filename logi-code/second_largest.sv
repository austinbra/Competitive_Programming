module second_largest #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  resetn,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout
);

    logic [DATA_WIDTH-1:0] first;
    logic [1:0]            count;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            first <= '0;
            dout <= '0;
            count <= 2'd0;
        end else begin
            unique case (count)
                2'd0: begin
                    first <= din;
                    dout <= '0;
                    count <= 2'd1;
                end

                2'd1: begin
                    count <= 2'd2;

                    if (din > first) begin
                        first <= din;
                        dout <= first;
                    end else begin
                        dout <= din;
                    end
                end

                default: begin
                    if (din >= first) begin
                        first <= din;
                        dout <= first;
                    end else if (din > dout) begin
                        dout <= din;
                    end
                end
            endcase
        end
    end

endmodule