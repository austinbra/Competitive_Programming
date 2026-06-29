module fib_gen #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  resetn,
    output logic [DATA_WIDTH-1:0] out
);
    logic [DATA_WIDTH-1:0] curr;
    logic [DATA_WIDTH-1:0] next;

    assign out = curr;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            curr <= DATA_WIDTH'(1);
            next <= DATA_WIDTH'(1);
        end else begin
            curr <= next;
            next <= curr + next;
        end
    end
endmodule
