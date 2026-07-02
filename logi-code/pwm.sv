module pwm_controller #(
    parameter PERIOD_BITS = 16,
    parameter DT_BITS     = 8
) (
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [PERIOD_BITS-1:0] period,
    input  logic [PERIOD_BITS-1:0] duty,
    input  logic [DT_BITS-1:0]     dead_time,
    output logic                   pwm_h,
    output logic                   pwm_l,
    output logic                   fault
);
    logic [PERIOD_BITS-1:0] count;

    logic [PERIOD_BITS-1:0] period_reg;
    logic [PERIOD_BITS-1:0] duty_reg;
    logic [DT_BITS-1:0] dead_time_reg;
    logic fault_pending;

    logic initialized;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count <= '0;
            pwm_h <= '0;
            pwm_l <= '0;
            fault <= '0;
            period_reg <= '0;
            duty_reg <= '0;
            dead_time_reg <= '0;
            initialized <= '0;
            fault_pending <= '0;
        end else begin
            if (!initialized) begin
                count <= '0;
                period_reg <= period;
                duty_reg <= duty;
                dead_time_reg <= dead_time;
                pwm_h <= '0;
                pwm_l <= '0;
                initialized <= 1'b1;
                fault_pending <= ((duty + dead_time) >= period);
            end else begin
                fault <= fault_pending;
                if (fault_pending) begin
                    pwm_h <= '0;
                    pwm_l <= '0;
                end else begin
                    pwm_h <= (duty_reg != '0) && (count < duty_reg);
                    pwm_l <= ((count >= (duty_reg + dead_time_reg)) && (count < (period_reg - dead_time_reg)));
                end
                if (count == period_reg - 1'b1) begin
                    count <= '0;
                    period_reg <= period;
                    duty_reg <= duty;
                    dead_time_reg <= dead_time;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end

endmodule