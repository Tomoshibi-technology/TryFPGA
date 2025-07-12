// spi.v -  汎用spi slave モジュール
module spi_slave(
    input  wire rst_n,
    input wire [7:0] tx_data,
    input wire tx_start,

    output reg [7:0] rx_data,
    output reg data_valid,

    input  wire sclk,
    input  wire cs,
    input  wire mosi,
    output reg  miso
);

reg [7:0] rx_shift_reg;
reg [7:0] tx_shift_reg;
reg [2:0] bit_cnt; // 3-bit counter for 8 bits

// MOSI - Receive
always @(posedge sclk) begin
  if (!rst_n) begin
    rx_shift_reg <= 8'b0;
    bit_cnt <= 3'b0;
    data_valid <= 1'b0;
  end else if (!cs) begin // Active low chip select
    if(bit_cnt == 3'd7) begin
      rx_shift_reg[7:0] <= 8'b0;
      rx_data[7:0] <= {rx_shift_reg[6:0], mosi};
      data_valid <= 1'b1;
    end else begin
      rx_shift_reg[7:0] <= {rx_shift_reg[6:0], mosi};
      data_valid <= 1'b0; 
      // TODO: SPIのクロックが止まってしまうと、0に戻せなくなるので、何かしらの対策が必要
    end
    bit_cnt <= bit_cnt + 1; // non-blocking assignment
  end
end

endmodule
