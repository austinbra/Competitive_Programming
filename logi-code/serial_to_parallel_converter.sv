module serial2parallel (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       din_serial,
    input  logic       din_valid,
    output logic [7:0] dout_parallel,
    output logic       dout_valid
);
    logic [3:0] count;
    logic [7:0] bitstr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_parallel <= '0;
            dout_valid    <= '0;
            count         <= '0;
            bitstr        <= '0;
        end else begin
            dout_valid <= '0; // default
            if (count == 4'd8) begin
                dout_parallel <= bitstr;
                dout_valid    <= 1'b1;
                count         <= '0;
                bitstr        <= '0;
            end else if (!din_valid) begin
                dout_parallel <= '0;
                count         <= '0;
                bitstr        <= '0;
            end else begin
                bitstr <= {bitstr[6:0], din_serial};
                count  <= count + 4'd1;
            end
        end
    end
endmodule