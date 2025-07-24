/*
動作の流れ
IDLE->LOAD->HI->LO->LOAD->HI->LO->...->RST

直したい
・stateによって、今のstateのo_neopixel_outの値を決めている場合と、次のstateのo_neopixel_outの値を決めている場合がある。
・1クロック分、適当にLOADを入れているが、本来ならば無くしたい。

各入出力の動き
  i_start: 立ち上がりで送信開始
  o_busy: IDLE状態以外で1
  o_rd_addr: 読み出したいアドレス、0からLEDS*3-1まで
    LO->LOADの遷移時に同時に変化
  i_data: データ入力 LOAD->HIの遷移時に読み出し
  o_neopixel_out: NeoPixelに出力するデータ
  o_frame_done: RST区間で1 = 1frame送信完了

  i_rst_n: 0でリセット
  i_clk: クロック入力
*/


module neopixel_driver #(
  parameter LEDS = 200,
  parameter CLK_HZ = 50_000_000
)(
  input wire i_clk,
  input wire i_rst_n,

  input wire i_start,
  output reg o_busy,

  output wire [$clog2(LEDS*3)-1:0] o_rd_addr, // 0x0000 to 0x
  input wire [7:0] i_data,

  output reg o_neopixel_out,
  output reg o_frame_done,

  output wire[7:0] o_debug_state
);

assign o_debug_state = r_clk_cnt[15:8]; // デバッグ用にクロックカウンタを出力

// localparam T0H_TCK = (CLK_HZ * 350 + 500_000_000) / 1_000_000_000; // 350ns
// localparam T0L_TCK = (CLK_HZ * 800 + 500_000_000) / 1_000_000_000; // 800ns  
// localparam T1H_TCK = (CLK_HZ * 700 + 500_000_000) / 1_000_000_000; // 700ns
// localparam T1L_TCK = (CLK_HZ * 600 + 500_000_000) / 1_000_000_000; // 600ns
// localparam RST_TCK = (CLK_HZ * 50 + 500_000) / 1_000_000; // 50us

// 50MHz (20ns/clock) での計算済み値
localparam T0H_TCK = 15;  // 220~380ns ÷ 20ns = 11~19
localparam T0L_TCK = 35;  // 580~1000ns ÷ 20ns = 29~50
localparam T1H_TCK = 25;  // 580ns ÷ 20ns = 29  
localparam T1L_TCK = 25;  // 580ns ÷ 20ns = 29
localparam RST_TCK = 2500; // 50us ÷ 20ns = 2500

typedef enum logic [2:0] {
  IDLE,
  LOAD,
  LOAD2,
  HI,
  LO,
  RST
} state_t;

state_t r_state = IDLE;

reg[15:0] r_clk_cnt = 0;
reg[2:0] r_bit_cnt = 0; // 0->7
reg[7:0] r_shift = 0;
reg [$clog2(LEDS*3)-1:0] r_byte_cnt = 0; // = address to read from

assign o_rd_addr = LEDS*3 - r_byte_cnt-1;


always @(posedge i_clk)begin
  if(!i_rst_n) begin
    r_state <= IDLE;
    r_clk_cnt <= 0;
    r_bit_cnt <= 0;
    r_shift <= 0;
    r_byte_cnt <= 0;
  end else begin
    case (r_state)
      IDLE: begin
        if(i_start) begin
          o_busy <= 1'b1;
          r_state <= LOAD;
          r_byte_cnt <= LEDS*3-1;
        end else begin
          o_neopixel_out <= 1'b0;
          o_busy <= 1'b0;
          o_frame_done <= 1'b0;
        end
      end
      LOAD: 
        r_state <= LOAD2;
      LOAD2: begin
        r_state <= HI;
        o_neopixel_out <= 1'b1;

        r_shift <= i_data;
        r_bit_cnt <= 3'd7;
        r_clk_cnt <= (i_data[7]) ? T1H_TCK-1 : T0H_TCK-1;
      end
      HI: begin
        if(r_clk_cnt == 0) begin 
          r_state <= LO;
          o_neopixel_out <= 1'b0;

          r_clk_cnt <= (r_shift[7]) ? T1L_TCK-1 : T0L_TCK-1;
        end else begin
          r_clk_cnt <= r_clk_cnt-1;
        end
      end
      LO: begin
        if(r_clk_cnt == 0) begin // ビット送信完了
          r_shift <= {r_shift[6:0], 1'b0}; // シフトレジスタを左シフト

          if(r_bit_cnt == 0)begin // 1バイト送信完了
            if(r_byte_cnt == 0) begin // 全ピクセル送信完了
              r_state <= RST;
              o_frame_done <= 1'b1;
              r_clk_cnt <= RST_TCK - 1;
            end else begin
              r_state <= LOAD;
              r_byte_cnt <= r_byte_cnt - 1;
            end
          end else begin
            r_bit_cnt <= r_bit_cnt - 1;

            r_state <= HI;
            o_neopixel_out <= 1'b1; // 次のビットを送信
            r_clk_cnt <= (r_shift[6]) ? T1H_TCK - 1 : T0H_TCK - 1;
          end
        end else begin
          r_clk_cnt <= r_clk_cnt - 1;
        end
      end
      RST: begin
        o_neopixel_out <= 1'b0;
        if(r_clk_cnt == 0) begin
          r_state <= IDLE;
        end else begin
          r_clk_cnt <= r_clk_cnt - 1;
        end
      end
    endcase
  end
end
endmodule
