// top.v  – Tang Primer 25K用 SPI Slave

module top (
    input wire clk50m,
    input wire rst_n,
    
    input wire sclk,
    input wire cs,
    input wire mosi,
    // output wire miso,

    output wire [8:0] led,
    output wire o_sclk,
    output wire o_cs,
    output wire o_mosi
); 

    wire data_valid;
    wire [7:0] rx_data;

    assign led[7:0] = rx_data[7:0]; // Display received data on LEDs
    assign led[8] = data_valid; // Indicate data valid status on the last LED

    assign o_sclk = sclk;
    assign o_cs = cs;
    assign o_mosi = mosi;

    // reg[$clog2(500)-1:0] clk_div;
    // always @(posedge clk50m) begin
    //     if (!rst_n) begin
    //         clk_div <= 0;
    //     end else begin
    //         clk_div <= clk_div + 1;
    //     end
    // end
    // assign led[0] = clk_div[$clog2(500)-1];

    spi_syn_slave my_spi_syn(
        .clk(clk50m),
        .rst_n(rst_n),

        .rx_data(rx_data),
        .data_valid(data_valid),

        .sclk(sclk),
        .cs(cs),
        .mosi(mosi)
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
