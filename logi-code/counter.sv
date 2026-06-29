module counter #(
    parameter MAX = 99,
    parameter DATA_WIDTH = 16
) (
    input logic clk,
    input logic reset,
    start,
    stop,
    output logic [DATA_WIDTH-1:0] count
);
    logic counting;
    logic counting_next;

    always_comb begin
        counting_next = counting;

        if (stop)
            counting_next = 1'b0;
        else if (start)
            counting_next = 1'b1;
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counting <= 1'b0;
            count    <= '0;
        end else begin
            counting <= counting_next;

            if (counting_next) begin
                if (count == MAX)
                    count <= '0;
                else
                    count <= count + 1'b1;
            end
        end
    end
endmodule