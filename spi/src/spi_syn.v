// spi.v -  汎用spi slave モジュール

/*
mosi から8bit受信してrx_dataに格納
csがLの時、sclkが立ち上がるごとに受信
csがs->hのdata_validが1になる
*/


module spi_syn_slave(
    input wire clk,
    input  wire rst_n,

    // input wire [7:0] tx_data,
    // input wire tx_start,
    
    output reg [7:0] rx_data,
    output wire data_valid,

    input  wire sclk,
    input  wire cs,
    input  wire mosi
    // output reg  miso
);

reg[2:0] buf_sclk, buf_cs, buf_mosi;

always @(posedge clk)begin
  if(!rst_n) begin
    buf_sclk <= 3'b111;
    buf_cs <= 3'b111;
    buf_mosi <= 3'b000;
  end else begin
    buf_sclk <= {buf_sclk[1:0], sclk};
    buf_cs <= {buf_cs[1:0], cs};
    buf_mosi <= {buf_mosi[1:0], mosi};
  end
end

wire sclk_rise;
wire cs_rise;
assign sclk_rise = ((buf_sclk[2]==1'b0)&&(buf_sclk[1]==1'b1))?1'b1:1'b0;
assign cs_rise = ((buf_cs[2]==1'b0)&&(buf_cs[1]==1'b1))?1'b1:1'b0;

reg [7:0] rx_shift_reg;
reg [2:0] bit_cnt;

reg [1:0] buf_data_valid;
assign data_valid = buf_data_valid[1];

always@(posedge clk) begin
  if(!rst_n) begin
    rx_data <= 8'b0;
    buf_data_valid <= 2'b0;
    bit_cnt <= 3'b0;
    rx_shift_reg <= 8'b0;
  end else begin
    if(sclk_rise) begin
      if(bit_cnt == 3'b111) begin
        bit_cnt <= 3'b0;
        rx_data <= {rx_shift_reg[6:0], buf_mosi[2]};
      end else begin
        bit_cnt <= (bit_cnt + 1) & 3'b111;
        rx_shift_reg <= {rx_shift_reg[6:0], buf_mosi[2]};
      end
    end else if(cs_rise) begin
      bit_cnt <= 3'b0;
      rx_shift_reg <= 8'b0;
    end
    buf_data_valid <= {buf_data_valid[0], (sclk_rise && (bit_cnt == 3'b111))};
  end
end
endmodule
