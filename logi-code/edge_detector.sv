module edge_detector (
    input  logic clk,
    input  logic resetn,
    input  logic din,
    output logic dout
);
    logic din_d;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            din_d <= 1'b0;
            dout  <= 1'b0;
        end else begin
            dout  <= din && ~din_d;
            din_d <= din;
        end
    end
endmodule