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
    localparam int FIZZ_W  = (FIZZ <= 1) ? 1 : $clog2(FIZZ);
    localparam int BUZZ_W  = (BUZZ <= 1) ? 1 : $clog2(BUZZ);
    localparam int COUNT_W = (MAX_CYCLES <= 1) ? 1 : $clog2(MAX_CYCLES + 1);

    localparam logic [COUNT_W-1:0] COUNT_FIRST = COUNT_W'(1);
    localparam logic [COUNT_W-1:0] COUNT_LAST  = COUNT_W'(MAX_CYCLES);
    localparam logic [FIZZ_W-1:0]  FIZZ_FIRST  = FIZZ_W'((FIZZ <= 1) ? 0 : 1);
    localparam logic [FIZZ_W-1:0]  FIZZ_LAST   = FIZZ_W'((FIZZ <= 1) ? 0 : (FIZZ - 1));
    localparam logic [BUZZ_W-1:0]  BUZZ_FIRST  = BUZZ_W'((BUZZ <= 1) ? 0 : 1);
    localparam logic [BUZZ_W-1:0]  BUZZ_LAST   = BUZZ_W'((BUZZ <= 1) ? 0 : (BUZZ - 1));

    logic [COUNT_W-1:0] counter;
    logic [FIZZ_W-1:0]  fizz_rem;
    logic [BUZZ_W-1:0]  buzz_rem;
    logic               fizz_now;
    logic               buzz_now;

    assign fizz_now = (fizz_rem == '0);
    assign buzz_now = (buzz_rem == '0);

    always_ff @(posedge clk) begin
        if (!resetn) begin
            counter  <= COUNT_FIRST;
            fizz_rem <= FIZZ_FIRST;
            buzz_rem <= BUZZ_FIRST;
            fizz     <= 1'b1;
            buzz     <= 1'b1;
            fizzbuzz <= 1'b1;
        end else begin
            fizz     <= fizz_now;
            buzz     <= buzz_now;
            fizzbuzz <= fizz_now && buzz_now;

            if (counter == COUNT_LAST) begin
                counter  <= COUNT_FIRST;
                fizz_rem <= FIZZ_FIRST;
                buzz_rem <= BUZZ_FIRST;
            end else begin
                counter <= counter + COUNT_FIRST;

                if (fizz_rem == FIZZ_LAST) begin
                    fizz_rem <= '0;
                end else begin
                    fizz_rem <= fizz_rem + FIZZ_W'(1);
                end

                if (buzz_rem == BUZZ_LAST) begin
                    buzz_rem <= '0;
                end else begin
                    buzz_rem <= buzz_rem + BUZZ_W'(1);
                end
            end
        end
    end
endmodule
