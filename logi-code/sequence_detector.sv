module seq_detector (
    input  logic clk,
    input  logic resetn,
    input  logic din,
    output logic dout
);
    logic [2:0] prev;
    assign dout = ({prev, din} == 4'b1010);

    always_ff @(posedge clk) begin
        if (!resetn) begin
            prev <= 3'b000;
        end else begin
            prev <= {prev[1:0], din};
        end
    end
endmodule