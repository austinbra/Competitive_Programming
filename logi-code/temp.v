module countdown(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire d,
    output reg rise,
    output reg fall
);  
    reg previous;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rise <= 1'b0;
            fall <= 1'b0;
            previous <= 1'b0;
        end else begin
            rise <= 1'b0;
            fall <= 1'b0;
            if (en) begin
                rise <= d & ~previous;
                fall <= ~d & previous;
                previous <= d;
            end
        end
    end
endmodule
