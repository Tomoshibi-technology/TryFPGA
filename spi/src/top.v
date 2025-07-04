// top.v  – Tang Nano 用 SPI Slave

module top (
    input wire clk27m,
    input wire rst_n,
    
    input wire sclk,
    input wire cs,
    input wire mosi,
    output wire miso
); 

    wire data_valid;
    wire [7:0] rx_data;

    spi_slave my_spi(
      .rst_n(rst_n),
      // .tx_data(),
      // .tx_start(),

      .rx_data(rx_data[7:0]),
      .data_valid(data_valid),

      .sclk(sclk),
      .cs(cs),
      .mosi(mosi),
      .miso(miso)
    );

endmodule
