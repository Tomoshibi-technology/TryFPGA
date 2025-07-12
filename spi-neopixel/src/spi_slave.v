// spi.v -  汎用spi slave モジュール

/*
mosi から8bit受信してo_rx_dataに格納
csがLの時、sclkが立ち上がるごとに受信
csがs->hのdata_validが1になる
*/


module spi_slave(
    input wire i_clk,
    input wire i_rst_n,
    
    output reg [7:0] o_rx_data,
    output wire o_data_valid,

    input wire i_sclk,
    input wire i_cs,
    input wire i_mosi

    // input wire [7:0] tx_data,
    // input wire tx_start,
    // output reg  miso
);

reg[2:0] r_buf_sclk, r_buf_cs, r_buf_mosi;

always @(posedge i_clk)begin
  if(!i_rst_n) begin
    r_buf_sclk <= 3'b111;
    r_buf_cs <= 3'b111;
    r_buf_mosi <= 3'b000;
  end else begin
    r_buf_sclk <= {r_buf_sclk[1:0], i_sclk};
    r_buf_cs <= {r_buf_cs[1:0], i_cs};
    r_buf_mosi <= {r_buf_mosi[1:0], i_mosi};
  end
end

wire w_sclk_rise;
wire w_cs_rise;
assign w_sclk_rise = ((r_buf_sclk[2]==1'b0)&&(r_buf_sclk[1]==1'b1))?1'b1:1'b0;
assign w_cs_rise = ((r_buf_cs[2]==1'b0)&&(r_buf_cs[1]==1'b1))?1'b1:1'b0;

reg [7:0] r_rx_shift_reg;
reg [2:0] r_bit_cnt;

reg [1:0] r_buf_data_valid;
assign o_data_valid = r_buf_data_valid[1];

always@(posedge i_clk) begin
  if(!i_rst_n) begin
    o_rx_data <= 8'b0;
    r_buf_data_valid <= 2'b0;
    r_bit_cnt <= 3'b0;
    r_rx_shift_reg <= 8'b0;
  end else begin
    if(w_sclk_rise) begin
      if(r_bit_cnt == 3'b111) begin
        r_bit_cnt <= 3'b0;
        o_rx_data <= {r_rx_shift_reg[6:0], r_buf_mosi[2]};
      end else begin
        r_bit_cnt <= (r_bit_cnt + 1) & 3'b111;
        r_rx_shift_reg <= {r_rx_shift_reg[6:0], r_buf_mosi[2]};
      end
    end else if(w_cs_rise) begin
      r_bit_cnt <= 3'b0;
      r_rx_shift_reg <= 8'b0;
    end
    r_buf_data_valid <= {r_buf_data_valid[0], (w_sclk_rise && (r_bit_cnt == 3'b111))};
  end
end
endmodule
