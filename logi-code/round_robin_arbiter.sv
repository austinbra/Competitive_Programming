module round_robin_arbiter #(
    parameter int N = 4
) (
    input  logic         clk,
    input  logic         resetn,
    input  logic [N-1:0] req,
    output logic [N-1:0] grant,
    output logic         valid
);

    logic [$clog2(N)-1:0] ptr;
    logic [$clog2(N)-1:0] ptr_next;

    logic [N-1:0] grant_next;
    logic valid_next;
    logic [$clog2(N):0]idx;

    always_comb begin
        grant_next = '0;
        valid_next = '0; //like a boolean check
        ptr_next = ptr;

        for (int i = 0; i < N; i++) begin
            idx = ptr + i;
            if (idx == N)
                idx = '0;

            if (!valid_next && req[idx]) begin
                grant_next[idx] = 1'b1;
                valid_next = 1'b1;
                ptr_next = (idx == N-1) ? '0 : idx + 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            ptr   <= '0;
            grant <= '0;
            valid <= 1'b0;
        end else begin
            ptr <= ptr_next;
            grant <= grant_next;
            valid <= valid_next;
        end
    end

endmodule