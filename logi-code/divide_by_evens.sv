module divide_by_evens_clock (
    input  logic clk,
    input  logic resetn,
    output logic div2,
    output logic div4,
    output logic div6
);
    logic       count4;
    logic [1:0] count6;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            div2   <= 1'b0;
            div4   <= 1'b0;
            div6   <= 1'b0;
            count4 <= 1'd1;
            count6 <= 2'd2;
        end else begin
            div2 <= ~div2;

            if (count4 == 1'd1) begin
                count4 <= 1'd0;
                div4   <= ~div4;
            end else begin
                count4 <= count4 + 1'd1;
            end

            if (count6 == 2'd2) begin
                count6 <= 2'd0;
                div6   <= ~div6;
            end else begin
                count6 <= count6 + 2'd1;
            end
        end
    end



endmodule