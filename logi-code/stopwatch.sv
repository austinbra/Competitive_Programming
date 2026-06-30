module stopwatch (
    input  logic       CLK,
    input  logic       RST,
    output logic [5:0] Hours,
    output logic [5:0] Mins,
    output logic [5:0] Secs
);

    localparam logic unsigned [$clog2(60)-1:0] SEC_LAST = 59;
    localparam logic unsigned [$clog2(60)-1:0] MIN_LAST = 59;
    localparam logic unsigned [$clog2(24)-1:0] HOUR_LAST = 23;

    logic sec_wrap;
    logic min_wrap;
    logic hour_wrap;

    assign sec_wrap  = (Secs  == SEC_LAST);
    assign min_wrap  = (Mins  == MIN_LAST);
    assign hour_wrap = (Hours == HOUR_LAST);

    always_ff @(posedge CLK or posedge RST) begin
        if (RST) begin
            Hours <= '0;
            Mins  <= '0;
            Secs  <= '0;
        end else begin
            Secs <= sec_wrap ? '0 : Secs + 1'b1;

            if (sec_wrap)
                Mins <= min_wrap ? '0 : Mins + 1'b1;

            if (sec_wrap && min_wrap)
                Hours <= hour_wrap ? '0 : Hours + 1'b1;
        end
    end

endmodule