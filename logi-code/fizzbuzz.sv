module fizzbuzz #(
    parameter int FIZZ = 3,
    parameter int BUZZ = 5,
    parameter int MAX_CYCLES = 100
) (
    input  logic clk,
    input  logic resetn,
    output logic fizz,
    output logic buzz,
    output logic fizzbuzz
);
    localparam int FIZZ_W  = $clog2(FIZZ);
    localparam int BUZZ_W  = $clog2(BUZZ);
    localparam int COUNT_W = $clog2(MAX_CYCLES + 1);

    localparam logic [FIZZ_W-1:0]  FIZZ_LAST   = FIZZ - 1;
    localparam logic [BUZZ_W-1:0]  BUZZ_LAST   = BUZZ - 1;

    logic [COUNT_W-1:0] counter;
    logic [FIZZ_W-1:0]  fizz_cnt;
    logic [BUZZ_W-1:0]  buzz_cnt;
    logic               fizz_now;
    logic               buzz_now;

    assign fizz_now = (fizz_cnt == '0);
    assign buzz_now = (buzz_cnt == '0);

    always_ff @(posedge clk) begin
        if (!resetn) begin
            counter  <= 1'b1;
            fizz_cnt <= 1'b1;
            buzz_cnt <= 1'b1;
            fizz <= 1'b1;
            buzz <= 1'b1;
            fizzbuzz <= 1'b1;
        end else begin
            fizz     <= fizz_now;
            buzz     <= buzz_now;
            fizzbuzz <= fizz_now && buzz_now;

            if (counter == MAX_CYCLES) begin
                counter  <= 1'b1;
                fizz_cnt <= 1'b1;
                buzz_cnt <= 1'b1;
            end else begin
                counter <= counter + 1'b1;

                if (fizz_cnt == FIZZ_LAST) begin
                    fizz_cnt <= '0;
                end else begin
                    fizz_cnt <= fizz_cnt + 1'b1;
                end

                if (buzz_cnt == BUZZ_LAST) begin
                    buzz_cnt <= '0;
                end else begin
                    buzz_cnt <= buzz_cnt + 1'b1;
                end
            end
        end
    end
endmodule
