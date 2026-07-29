`timescale 1ns/1ps

module crc16_ccitt #(
    parameter logic [15:0] POLY = 16'h1021,
    parameter logic [15:0] INIT = 16'hFFFF
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       clear_i,
    input  logic       valid_i,
    input  logic [7:0] data_i,
    output logic [15:0] crc_o
);

function automatic logic [15:0] next_crc_byte(
    input logic [15:0] crc,
    input logic [7:0] data
);
    logic [15:0] c; //is it better here to use reutron or to include an output logic. also what does automatic do?
    begin
        c = crc ^ {data, 8'd0};
        for (int i = 0; i < 8; i++) begin
            if (c[15])
                c = (c << 1) ^ POLY;
            else
                c = (c << 1);
        end
        return c;
    end
endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_o <= INIT;
    end else if (clear_i) begin
      crc_o <= INIT;
    end else if (valid_i) begin
      crc_o <= next_crc_byte(crc_o, data_i);
    end
  end

endmodule


