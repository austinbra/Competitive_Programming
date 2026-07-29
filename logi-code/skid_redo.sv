module skid_buffer #(
    parameter int DATA_W = 32
) (
    input  logic              clk,
    input  logic              rst_n,   // synchronous active-low reset

    // Upstream/source side
    input  logic              s_valid,
    output logic              s_ready,
    input  logic [DATA_W-1:0] s_data,

    // Downstream/sink side
    output logic              m_valid,
    input  logic              m_ready,
    output logic [DATA_W-1:0] m_data
);
    logic skid_full;
    logic [DATA_W-1:0] skid_data;
    logic s_fire;
    logic m_fire;

    assign m_valid = rst_n && (skid_full || s_valid);
    assign m_data = skid_full ? skid_data : s_data;

    assign s_ready = rst_n && (!skid_full || m_ready);

    assign s_fire = s_valid && s_ready;
    assign m_fire = m_valid && m_ready;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            skid_full <= 1'b0;
            skid_data <= '0;
        end else begin
            case ({s_fire, m_fire})

                2'b10: begin
                    skid_full <= 1'b1;
                    skid_data <= s_data;
                end

                2'b01: begin
                    skid_full <= 1'b0;
                end

                2'b11: begin
                    if (skid_full) begin
                        skid_data <= s_data;
                    end
                end

                default: begin
                    skid_full <= skid_full;
                    skid_data <= skid_data;
                end

            endcase
        end
    end

endmodule