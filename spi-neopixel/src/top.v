// top.v  – Tang Primer 25K用 SPI Slave

module top (
    input wire i_clk50m,
    input wire i_rst_n,
    
    input wire i_sclk,
    input wire i_cs,
    input wire i_mosi,
    // output wire o_miso,

    output wire [8:0] o_led,
    output wire o_sclk,
    output wire o_cs,
    output wire o_mosi
); 

    wire w_data_valid;
    wire [7:0] w_rx_data;

    assign o_led[7:0] = w_rx_data[7:0]; // Display received data on LEDs
    assign o_led[8] = w_data_valid; // Indicate data valid status on the last LED

    assign o_sclk = i_sclk;
    assign o_cs = i_cs;
    assign o_mosi = i_mosi;

    spi_slave my_spi(
        .i_clk(i_clk50m),
        .i_rst_n(i_rst_n),

        .o_rx_data(w_rx_data),
        .o_data_valid(w_data_valid),

        .i_sclk(i_sclk),
        .i_cs(i_cs),
        .i_mosi(i_mosi)
    );

        // reg[$clog2(500)-1:0] r_clk_div;
    // always @(posedge i_clk50m) begin
    //     if (!i_rst_n) begin
    //         r_clk_div <= 0;
    //     end else begin
    //         r_clk_div <= r_clk_div + 1;
    //     end
    // end
    // assign o_led[0] = r_clk_div[$clog2(500)-1];

endmodule
