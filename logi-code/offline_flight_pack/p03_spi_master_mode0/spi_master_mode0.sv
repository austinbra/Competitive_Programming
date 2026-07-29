`timescale 1ns/1ps

module spi_master_mode0 #(
    parameter int DATA_WIDTH = 8,
    // CLK_DIV is the full SCLK period measured in system clk cycles.
    // This simple implementation assumes CLK_DIV is even.
    parameter int CLK_DIV = 4
) (
    // System-side interface: normal RTL logic talks to these signals.
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [DATA_WIDTH-1:0] tx_data_i,     // parallel word to serialize onto MOSI
    input  logic                  start_i,       // one-cycle request to start one SPI word
    output logic [DATA_WIDTH-1:0] rx_data_o,     // received word; valid when done_pulse_o is high
    output logic                  busy_o,        // high while a transaction is active
    output logic                  done_pulse_o,  // one clk pulse when the word is complete

    // SPI-pin interface: these would connect to the external peripheral.
    input  logic                  miso_i,        // one serial bit from peripheral to master
    output logic                  mosi_o,        // one serial bit from master to peripheral
    output logic                  sclk_o,        // SPI clock generated from clk by div_cnt
    output logic                  cs_n_o         // active-low chip select; low frames the transaction
);

    // SCLK has two halves: low time and high time. Since CLK_DIV is the full
    // SCLK period, we toggle SCLK every CLK_DIV/2 system clocks.
    localparam int HALF_DIV = (CLK_DIV <= 1) ? 1 : (CLK_DIV / 2);
    localparam int DIV_W = (HALF_DIV <= 1) ? 1 : $clog2(HALF_DIV);
    localparam int COUNT_W = (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH + 1);

    logic [DIV_W-1:0] div_cnt;       // counts clk cycles until the next SCLK toggle
    logic [COUNT_W-1:0] bit_count;   // counts how many MISO bits have been sampled

    // Remaining transmit bits, left-aligned. MOSI always drives the MSB.
    // Example for tx_data_i=8'b00111100:
    //   start: mosi_o=bit7, tx_shift holds bits 6..0 shifted left
    //   next falling edges: mosi_o gets tx_shift[7], then tx_shift shifts left
    logic [DATA_WIDTH-1:0] tx_shift;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_o    <= '0;
            busy_o       <= 1'b0;
            done_pulse_o <= 1'b0;
            mosi_o       <= 1'b0;
            sclk_o       <= 1'b0;  // mode 0 idle clock level is low
            cs_n_o       <= 1'b1;  // not selected while idle/reset
            div_cnt      <= '0;
            bit_count    <= '0;
            tx_shift     <= '0;
        end else begin
            // Default to no completion pulse. The finish condition below sets it
            // for exactly one clk cycle.
            done_pulse_o <= 1'b0;

            if (!busy_o) begin
                // Idle/setup branch. This is not the transfer work; it waits for
                // start_i and initializes the transaction. Because these are
                // nonblocking assignments, busy_o becomes 1 after this clock edge.
                cs_n_o    <= 1'b1;
                sclk_o    <= 1'b0;
                div_cnt   <= '0;
                bit_count <= '0;

                if (start_i) begin
                    busy_o    <= 1'b1;
                    cs_n_o    <= 1'b0;
                    mosi_o    <= tx_data_i[DATA_WIDTH-1];
                    tx_shift  <= tx_data_i << 1;  // first MOSI bit is already driven
                    rx_data_o <= '0;              // reused as the receive shift register
                end
            end else if (div_cnt == HALF_DIV - 1) begin
                // Time to toggle SCLK. Work happens only on these half-period ticks.
                div_cnt <= '0;

                if (!sclk_o) begin
                    // Current SCLK is low, so this tick creates a rising edge.
                    // SPI mode 0 samples MISO on the rising edge.
                    sclk_o    <= 1'b1;
                    rx_data_o <= (rx_data_o << 1) | miso_i;

                    if (bit_count == DATA_WIDTH - 1) begin
                        // This rising edge sampled the final bit. rx_data_o is assigned
                        // the completed word including this just-sampled miso_i bit.
                        // The idle branch on the next clk returns CS_N high and SCLK low.
                        busy_o       <= 1'b0;
                        done_pulse_o <= 1'b1;
                    end else begin
                        bit_count <= bit_count + 1'b1;
                    end
                end else begin
                    // Current SCLK is high, so this tick creates a falling edge.
                    // SPI mode 0 changes MOSI on falling edges so it is stable
                    // before the next rising/sample edge.
                    sclk_o   <= 1'b0;
                    mosi_o   <= tx_shift[DATA_WIDTH-1];
                    tx_shift <= tx_shift << 1;
                end
            end else begin
                // Wait until the next half-period tick.
                div_cnt <= div_cnt + 1'b1;
            end
        end
    end

endmodule
