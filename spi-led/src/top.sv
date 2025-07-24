// top.v  – Tang Primer 25K用 SPI Slave

module top (
  input wire i_clk50m,
  input wire i_rst_n,
  
  input wire i_sclk,
  input wire i_cs,
  input wire i_mosi,
  // output wire o_miso,

  output wire o_neopixel_out,

  output wire [7:0] o_debug_led,
  output wire o_debug_sclk,
  output wire o_debug_cs,
  output wire o_debug_mosi
); 

  localparam LEDS = 30;
  localparam ADDR_WIDTH = $clog2(LEDS*3);

  // assign o_debug_led[7:0] = w_rx_data[7:0]; // Display received data on LEDs
  assign o_debug_led[7:0] = w_debug_state[7:0];
  assign o_debug_sclk = i_sclk;
  assign o_debug_cs = i_cs;
  assign o_debug_mosi = i_mosi;

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
  reg [ADDR_WIDTH-1:0] r_index = 0;
  // reg [7:0] r_data_bridge = 0;
  reg [2:0] r_frame_valid = 0;
  // reg r_frame_valid = 0;

  wire [7:0] w_rx_data;
  wire w_data_valid;

  //data_valid を2クロック分出すようにしないとダメな気がする

  always @(posedge i_clk50m) begin
    if(!i_rst_n) begin
      r_spi_state <= IDLE;
      r_index <= 0;
      // r_data_bridge <= 0;
      r_frame_valid <= 0;
    end else begin
      r_frame_valid <= {r_frame_valid[1:0], 1'b0};
      case(r_spi_state)
        IDLE: begin
          // r_frame_valid <= 0; // フレーム有効フラグをリセット
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
            // r_data_bridge <= w_rx_data;
            r_spi_state <= DATA_W;
          end
        end
        DATA_W: begin
          //このstateになると自動でw_write_enが1になっている。
          if(r_index < LEDS*3) begin
            r_index <= (r_index + 1) & {ADDR_WIDTH{1'b1}};
            r_spi_state <= DATA_R; // 次のデータを受信する
          end else begin
            r_spi_state <= STOP; // LEDS*3バイト受信完了
          end
        end
        STOP: begin
          // if(w_data_valid == 1) begin
            if(w_rx_data == 8'hAA) begin
              r_spi_state <= IDLE; // ストップバイトを受信してリセット
              r_frame_valid <= {r_frame_valid[1:0], 1'b1}; // フレーム完了
              // r_frame_valid <= 1'b1;
            end else begin
              r_spi_state <= IDLE; // ストップバイトが受信されなかった場合
            end
          // end
        end
      endcase
    end
  end

  wire w_write_en = (r_spi_state == DATA_W);
  wire [ADDR_WIDTH-1:0] w_write_addr = r_index;
  // wire [7:0] w_write_data = r_data_bridge;
  wire [7:0] w_write_data = w_rx_data;

  spi_slave my_spi(
    .i_clk(i_clk50m),
    .i_rst_n(i_rst_n),

    .o_rx_data(w_rx_data),
    .o_data_valid(w_data_valid),

    .i_sclk(i_sclk),
    .i_cs(i_cs),
    .i_mosi(i_mosi)
  );

  wire w_neopixel_start;
  wire [ADDR_WIDTH-1:0] w_neopixel_addr;
  wire [7:0] w_neopixel_data;

  double_buffer #(
    .LEDS(LEDS),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) my_double_buffer (
    .i_clk(i_clk50m),
    .i_rst_n(i_rst_n),

    .i_wr_en(r_spi_state == DATA_W),
    .i_wr_addr(r_index),
    .i_wr_data(w_write_data),
    .i_swap(r_frame_valid[0]),

    .i_rd_addr(w_neopixel_addr),
    .o_rd_data(w_neopixel_data)
    // .o_read_frame_valid(w_neopixel_start)
  );

  // LED制御
  neopixel_driver #(
    .LEDS(LEDS)
  ) my_neopixel (
    .i_clk(i_clk50m),
    .i_rst_n(i_rst_n),
    .i_start(r_frame_valid[2]), // フレーム有効信号
    .i_data(w_neopixel_data), // 書き込みデータ
    .o_rd_addr(w_neopixel_addr), // 読み出しアドレス
    .o_neopixel_out(o_neopixel_out),
    .o_busy(),
    .o_frame_done(), // フレーム完了信号は使用しない
    .o_debug_state(w_debug_state) // デバッグ用状態出力
  );

  wire [7:0] w_debug_state;

endmodule



