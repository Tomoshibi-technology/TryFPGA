// top.v  – Tang Primer 25K用 SPI Slave

module top (
  input wire i_clk50m,
  input wire i_rst_n,
  
  input wire i_sclk,
  input wire i_cs,
  input wire i_mosi,
  // output wire o_miso,

  output wire [5:0] o_neopixel_out,

  output wire [7:0] o_debug_led,
  output wire o_debug_sclk,
  output wire o_debug_cs,
  output wire o_debug_mosi
); 

  // localparam LEDS = 400;
  // localparam ADDR_WIDTH = $clog2(LEDS*3);

  localparam CH_NUM = 6;
  localparam LEDS_PER_CH = 200;
  localparam BYTES_PER_CH = LEDS_PER_CH * 3;
  localparam LEDS_TOTAL = CH_NUM * LEDS_PER_CH;
  localparam BYTES_TOTAL = LEDS_TOTAL * 3;

  localparam ADDR_W_TOTAL = $clog2(BYTES_TOTAL);
  localparam ADDR_W_CH = $clog2(BYTES_PER_CH);


  // assign o_debug_led[7:0] = w_debug_state[7:0];
  assign o_debug_sclk = i_sclk;
  assign o_debug_cs = i_cs;
  assign o_debug_mosi = i_mosi;
  assign o_debug_led[7:0] = {2'b00, w_neopixel_out_bus[5:0]};

  // spi controller
  /*
    プロトコル
      スタートバイト 0x55 0x5B
      受信データ LEDS*3バイト
      ストップバイト 0xAA
    スタートバイトを受信後の動作の流れ
      indexをカウントアップしながら、double_bufferに書き込み;
      LEDS*3バイト受信後、i_write_frame_doneを1にする(スワップされる)
  */

  typedef enum reg [2:0] {
    IDLE,
    START,
    DATA_R,
    DATA_W,
    STOP
  } spi_state_t;

  spi_state_t r_spi_state = IDLE;
  reg [ADDR_W_TOTAL-1:0] r_index = 0;
  reg [2:0] r_frame_valid = 3'b000;

  wire [7:0] w_rx_data;
  wire w_data_valid;

  spi_slave my_spi(
    .i_clk(i_clk50m),
    .i_rst_n(i_rst_n),

    .o_rx_data(w_rx_data),
    .o_data_valid(w_data_valid),

    .i_sclk(i_sclk),
    .i_cs(i_cs),
    .i_mosi(i_mosi)
  );

  always @(posedge i_clk50m) begin
    if(!i_rst_n) begin
      r_spi_state <= IDLE;
      r_index <= 0;
      r_frame_valid <= 0;
    end else begin
      r_frame_valid <= {r_frame_valid[1:0], 1'b0};
      case(r_spi_state)
        IDLE: begin
          if(w_data_valid && w_rx_data == 8'h55) begin
            r_spi_state <= START;
            r_index <= 0;
          end
        end
        START: begin
          if(w_data_valid == 1)begin
            if(w_rx_data == 8'h5B) begin
              r_spi_state <= DATA_R;
            end else if(w_rx_data == 8'h55) begin
              r_spi_state <= START; // スタートバイトが連続して受信された場合
            end else begin
              r_spi_state <= IDLE; // スタートバイトが違うのでリセット
            end
          end
        end
        DATA_R: begin
          if(w_data_valid) begin
            r_spi_state <= DATA_W;
          end
        end
        DATA_W: begin
          //このstateになると自動でw_write_enが1になっている。
          if(r_index < BYTES_TOTAL) begin
            r_index <= (r_index + 1'b1) & {ADDR_W_TOTAL{1'b1}};
            r_spi_state <= DATA_R; // 次のデータを受信する
          end else begin
            r_spi_state <= STOP; // LEDS*3バイト受信完了
          end
        end
        STOP: begin
            if(w_rx_data == 8'hAA) begin
              r_spi_state <= IDLE; // ストップバイトを受信してリセット
              r_frame_valid <= {r_frame_valid[1:0], 1'b1}; // フレーム完了
            end else begin
              r_spi_state <= IDLE; // ストップバイトが受信されなかった場合
            end
          // end
        end
      endcase
    end
  end
  wire w_write_en = (r_spi_state == DATA_W);
  wire [7:0] w_write_data = w_rx_data; 

  wire [CH_NUM-1:0] w_neopixel_out_bus;
  wire [7:0]        w_debug_state_bus [CH_NUM-1:0];

  genvar ch;
  generate
    for (ch = 0; ch < CH_NUM; ch++) begin : g_ch
      /* 書き込みイネーブル & アドレス（600 byte 区切りで判定） */
      localparam int OFFSET = ch * BYTES_PER_CH;   // 0,600,1200...

      wire wr_en_local  = w_write_en &&
                          (r_index >= OFFSET) &&
                          (r_index <  OFFSET + BYTES_PER_CH);

      wire [ADDR_W_CH-1:0] wr_addr_local = r_index[ADDR_W_TOTAL-1:0] - OFFSET;

      /* ダブルバッファ（1ch 分）---------------------------------- */
      wire [ADDR_W_CH-1:0] rd_addr_local;
      wire [7:0]           rd_data_local;

      double_buffer #(
          .LEDS       (LEDS_PER_CH),
          .ADDR_WIDTH (ADDR_W_CH)
      ) u_buf (
          .i_clk   (i_clk50m),
          .i_rst_n (i_rst_n),
          .i_wr_en (wr_en_local),
          .i_wr_addr(wr_addr_local),
          .i_wr_data(w_write_data),
          .i_swap  (r_frame_valid[0]),   // 全 ch 同期スワップ
          .i_rd_addr(rd_addr_local),
          .o_rd_data(rd_data_local)
      );

      /* NeoPixel ドライバ（1ch 分）------------------------------ */
      wire neopix_out_local;
      wire [7:0] debug_state_local;

      neopixel_driver #(
          .LEDS (LEDS_PER_CH)
      ) u_drv (
          .i_clk   (i_clk50m),
          .i_rst_n (i_rst_n),
          .i_start (r_frame_valid[2]),   // 全 ch 同期開始
          .i_data  (rd_data_local),
          .o_rd_addr(rd_addr_local),
          .o_neopixel_out(neopix_out_local),
          .o_busy (),
          .o_frame_done(),
          .o_debug_state(debug_state_local)
      );

      /* バスに束ねる */
      assign w_neopixel_out_bus[ch]   = neopix_out_local;
      assign w_debug_state_bus[ch]    = debug_state_local;
    end
  endgenerate

  assign o_neopixel_out = w_neopixel_out_bus;

endmodule



