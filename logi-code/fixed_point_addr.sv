module fixed_point_adder #(
    parameter int Q = 15,
    parameter int N = 32
) (
    input  logic [N-1:0] a,
    input  logic [N-1:0] b,
    output logic [N-1:0] c
);

    localparam int MAG_W = N - 1;

    logic             sign_a;
    logic             sign_b;
    logic [MAG_W-1:0] mag_a;
    logic [MAG_W-1:0] mag_b;

    assign sign_a = a[N-1];
    assign sign_b = b[N-1];

    assign mag_a = a[N-2:0];
    assign mag_b = b[N-2:0];

    always_comb begin
        if (sign_a == sign_b) begin
            c[N-1]   = sign_a;
            c[N-2:0] = mag_a + mag_b;
        end else begin
            if (mag_a > mag_b) begin
                c[N-1]   = sign_a;
                c[N-2:0] = mag_a - mag_b;
            end else if (mag_b > mag_a) begin
                c[N-1]   = sign_b;
                c[N-2:0] = mag_b - mag_a;
            end else begin
                c = '0;
            end
        end
    end

endmodule