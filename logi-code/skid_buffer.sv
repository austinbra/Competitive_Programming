module skid_buffer #(
    parameter DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  resetn,
    input  logic                  s_valid,
    input  logic [DATA_WIDTH-1:0] s_data,
    output logic                  s_ready,
    input  logic                  m_ready,
    output logic                  m_valid,
    output logic [DATA_WIDTH-1:0] m_data
);
    //valid = valid data
    //ready = ready to receive
    //fire  = transfer happens now, at this clock edge.

    logic [DATA_WIDTH-1:0] skid_data;
    logic skid_valid;

    always_comb begin // sets m_valid and m_data
        if (!resetn) begin
            m_valid = 1'b0;
            m_data  = '0;
        end else begin
            if (skid_valid) begin
                m_valid = 1'b1;
                m_data  = skid_data;
            end else begin
                m_valid = s_valid;
                m_data = s_data;
            end
        end
    end
    always_ff @(posedge clk) begin //only sets skid and s_ready
        if (!resetn) begin
            s_ready <= 1'b1;
            skid_data <= '0;
            skid_valid <= '0;
        end else begin
            if (skid_valid) begin
                if (m_valid) begin 
                    s_ready <= 1'b1;
                    skid_valid <= '0;
                end else begin
                    s_ready <= '0;
                end
            end else begin
                if (s_ready && s_valid && !m_ready) begin //since m_valid = s_valid when skid is empty
                    skid_data <= s_data;
                    skid_valid <= 1'b1;
                    s_ready <= '0;
                end else begin
                    s_ready <= 1'b1;
                end
            end
        end
    end
endmodule