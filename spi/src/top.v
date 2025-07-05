// top.v  – Tang Primer 25K用 SPI Slave

module top (
    input wire clk50m,
    input wire rst_n,
    
    input wire sclk,
    input wire cs,
    input wire mosi,
    output wire miso
); 

    wire data_valid;
    wire [7:0] rx_data;

    spi_syn_slave my_spi_syn(
        .clk(clk50m),
        .rst_n(rst_n),

        .rx_data(rx_data),
        .data_valid(data_valid),

        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso)
    );

    // spi_slave my_spi(
    //   .rst_n(rst_n),
    //   // .tx_data(),
    //   // .tx_start(),

    //   .rx_data(rx_data[7:0]),
    //   .data_valid(data_valid),

    //   .sclk(sclk),
    //   .cs(cs),
    //   .mosi(mosi),
    //   .miso(miso)
    // );

endmodule
