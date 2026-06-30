module lfsr_prng #(
    parameter WIDTH = 16,
    parameter TAPS  = 16'hB400
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             en,
    input  logic [WIDTH-1:0] seed,
    input  logic             load,
    output logic [WIDTH-1:0] prng_out,
    output logic             valid
);
    logic feedback;
    assign feedback = ^(prng_out & TAPS);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            prng_out <= '1;
            valid <= '0;
        end else begin
            if (load) begin
                prng_out <= seed;
                valid <= '0;
            end else if (en) begin
                valid <= 1'b1;
                prng_out <= {feedback, prng_out[WIDTH-1:1]};
            end else begin
                valid <= '0;
            end
        end
    end
endmodule