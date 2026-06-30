module reg_file (
    input  logic [7:0] din,
    input  logic [2:0] addr,
    input  logic       wr,
    input  logic       rd,
    input  logic       clk,
    input  logic       resetn,
    output logic [7:0] dout,
    output logic       error
);
    logic [7:0] store [0:7];

    integer i;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            dout  <= '0;
            error <= 1'b0;

            for (i = 0; i < 8; i++) begin
                store[i] <= '0;
            end
        end else begin
            dout  <= '0;
            error <= 1'b0;

            if (rd && wr) begin
                error <= 1'b1;
            end else if (rd) begin
                dout <= store[addr];
            end else if (wr) begin
                store[addr] <= din;
            end
        end
    end
endmodule