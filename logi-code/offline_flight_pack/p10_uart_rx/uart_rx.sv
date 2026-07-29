module uart_rx #(
    parameter int CLKS_PER_BIT = 8
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx_i,
    output logic [7:0] data_o,
    output logic       valid_o,
    output logic       framing_error_o,
    output logic       busy_o
);
    localparam int COUNT_W = $clog2(CLKS_PER_BIT);
    localparam int HALF_CLKS = CLKS_PER_BIT / 2;

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    logic r1, r2;

    state_t state;
    logic [COUNT_W-1:0] count;
    logic [$clog2(8)-1:0] idx;
    logic [7:0] mem;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= '0;
            idx <= '0;
            mem <= '0;
            data_o <= '0;
            valid_o <= '0;
            framing_error_o  <= '0;
            busy_o <= '0;
            r1 <= 1'b1;
            r2 <= 1'b1;
        end else begin
            r1 <= rx_i;
            r2 <= r1;
            valid_o <= '0;
            framing_error_o <= '0;

            case (state)
                IDLE: begin
                    busy_o <= '0;
                    count <= '0;
                    idx  <= '0;
                    if (!r2) begin
                        state <= START;
                        busy_o  <= 1'b1;
                    end
                end

                START: begin
                    if (count == HALF_CLKS - 1) begin
                        count <= '0;
                        if (!r2) begin
                            state <= DATA;
                            idx <= '0;
                        end else begin
                            state <= IDLE;
                            busy_o  <= '0;
                        end
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                DATA: begin
                    if (count == CLKS_PER_BIT - 1) begin
                        count <= '0;
                        mem[idx] <= r2;
                        if (idx == 3'd7) begin
                            state <= STOP;
                        end else begin
                            idx <= idx + 1'b1;
                        end
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                STOP: begin
                    if (count == CLKS_PER_BIT - 1) begin
                        count <= '0;
                        state <= IDLE;
                        busy_o <= '0;
                        if (r2) begin
                            data_o <= mem;
                            valid_o <= 1'b1;
                        end else begin
                            framing_error_o <= 1'b1;
                        end
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    count <= '0;
                    idx <= '0;
                    busy_o <= '0;
                end
            endcase
        end
    end
endmodule