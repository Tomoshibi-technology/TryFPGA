// spidev_stream.c
#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

#include "neopixel_cordinates.h"
#include "ball_physics.h"

#define LEDS 1200
#define DISPLAY_RADIUS 90.0f  // ディスプレイの半径 (180mm/2)
#define GRAVITY_STRENGTH 0.001f  // 重力をさらにさらに弱く（大きな球も端まで動けるように）
#define MAX_BALLS 10  // 最大球数

// LED データを送信する関数
int send_led_data(int fd, uint8_t *led) {
  /*プロトコル
      スタートバイト 0x55 0x5B
      受信データ LEDS*3バイト
      ストップバイト 0xAA
  */
  static char tx_data[LEDS * 3 + 3];
  tx_data[0] = 0x55;
  tx_data[1] = 0x5B;
  memcpy(&tx_data[2], led, LEDS * 3);
  tx_data[LEDS * 3 + 2] = 0xAA; //End

  ssize_t n = write(fd, tx_data, sizeof(tx_data));
  if (n < 0) {
      perror("write");
      return -1;
  }
  return 0;
}

// 球の初期化ヘルパー関数（HSV版）
Ball create_ball_hsv(float x, float y, float vx, float vy, 
                    float base_radius, float radius_amp, float radius_freq, float radius_phase,
                    float base_hue, float hue_amp, float hue_freq, float hue_phase,
                    float base_sat, float sat_amp, float sat_freq, float sat_phase,
                    float base_val, float val_amp, float val_freq, float val_phase) {
    Ball ball = {
        .x = x, .y = y,
        .velocity_x = vx, .velocity_y = vy,
        .radius = base_radius,
        .collision_count = 0,
        .base_radius = base_radius,
        .radius_amplitude = radius_amp,
        .radius_frequency = radius_freq,
        .radius_phase = radius_phase,
        .base_hue = base_hue, .hue_amplitude = hue_amp, .hue_frequency = hue_freq, .hue_phase = hue_phase,
        .base_saturation = base_sat, .saturation_amplitude = sat_amp, .saturation_frequency = sat_freq, .saturation_phase = sat_phase,
        .base_value = base_val, .value_amplitude = val_amp, .value_frequency = val_freq, .value_phase = val_phase
    };
    
    // 初期HSV値を設定してRGBに変換
    ball.h = base_hue;
    ball.s = base_sat;
    ball.v = base_val;
    hsv_to_rgb(ball.h, ball.s, ball.v, &ball.r, &ball.g, &ball.b);
    
    return ball;
}

int main(void)
{
  const char *dev = "/dev/spidev4.0";
  uint8_t  mode  = SPI_MODE_3;
  uint32_t speed = 10 * 1000 * 1000;

  int fd = open(dev, O_WRONLY);
  if (fd < 0) { perror("open"); return 1; }

  ioctl(fd, SPI_IOC_WR_MODE,          &mode);
  ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ,  &speed);

  unsigned int frame_count = 0;
  static uint8_t led[LEDS * 3];
  
  // 球の配列と球数
  Ball balls[MAX_BALLS];
  int num_balls = 5;  // 適度な球数に調整
  
  // 球の初期化データ（HSV配列で管理）
  typedef struct {
      float x, y, vx, vy;
      float base_radius, radius_amp, radius_freq, radius_phase;
      float base_hue, hue_amp, hue_freq, hue_phase;
      float base_sat, sat_amp, sat_freq, sat_phase;
      float base_val, val_amp, val_freq, val_phase;
  } BallConfigHSV;
  
  BallConfigHSV ball_configs[MAX_BALLS] = {
      // Ball 1: 深いブルー系 - 大きめサイズ（メイン球）
      {-50.0f, 30.0f, 0.25f, -0.18f,
       25.0f, 12.0f, 0.010f, 0.0f,
       240.0f, 30.0f, 0.012f, 0.0f,    // 青色相 (240°) ±30°
       0.65f, 0.15f, 0.015f, 1.0f,     // 彩度を下げる (0.65) ±0.15
       0.28f, 0.15f, 0.018f, 2.0f},    // 明度を上げる (0.28) ±0.15 範囲:0.13~0.43
      
      // Ball 2: 鮮やかなピンク系
      {30.0f, -20.0f, -0.16f, 0.11f,
       14.7f, 5.0f, 0.009f, 0.0f,
       320.0f, 40.0f, 0.020f, 3.0f,    // ピンク色相 (320°) ±40°
       0.7f, 0.1f, 0.016f, 4.0f,       // 彩度を下げる (0.7) ±0.1
       0.27f, 0.18f, 0.014f, 5.0f},    // 明度を下げる (0.27) ±0.18 範囲:0.09~0.45
      
      // Ball 3: 鮮やかなグリーン系
      {-25.0f, 35.0f, 0.18f, -0.14f,
       10.5f, 5.0f, 0.012f, 1.0f,
       120.0f, 25.0f, 0.014f, 1.5f,    // 緑色相 (120°) ±25°
       0.68f, 0.12f, 0.022f, 2.5f,     // 彩度を下げる (0.68) ±0.12
       0.28f, 0.22f, 0.012f, 3.5f},    // 明度を下げる (0.28) ±0.22
      
      // Ball 4: 神秘的なパープル系
      {40.0f, 15.0f, -0.13f, -0.18f,
       16.8f, 6.0f, 0.011f, 2.0f,
       280.0f, 35.0f, 0.018f, 4.5f,    // 紫色相 (280°) ±35°
       0.6f, 0.2f, 0.024f, 5.5f,       // 彩度を下げる (0.6) ±0.2
       0.29f, 0.16f, 0.016f, 6.5f},    // 明度を下げる (0.29) ±0.16 範囲:0.13~0.45
      
      // Ball 5: 暖かいオレンジ系
      {-40.0f, -30.0f, 0.20f, 0.21f,
       15.8f, 6.0f, 0.010f, 1.5f,
       30.0f, 20.0f, 0.026f, 2.0f,     // オレンジ色相 (30°) ±20°
       0.72f, 0.1f, 0.020f, 3.0f,      // 彩度を下げる (0.72) ±0.1
       0.31f, 0.17f, 0.014f, 4.0f},    // 明度を下げる (0.31) ±0.17 範囲:0.14~0.48
      
      // Ball 6以降は使用しない
      {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f},
      {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f},
      {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f},
      {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f},
      {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f, 0, 0, 0.0f, 0.0f}
  };
  
  // 設定データから球を初期化
  for (int i = 0; i < num_balls; i++) {
      BallConfigHSV *cfg = &ball_configs[i];
      balls[i] = create_ball_hsv(
          cfg->x, cfg->y, cfg->vx, cfg->vy,
          cfg->base_radius, cfg->radius_amp, cfg->radius_freq, cfg->radius_phase,
          cfg->base_hue, cfg->hue_amp, cfg->hue_freq, cfg->hue_phase,
          cfg->base_sat, cfg->sat_amp, cfg->sat_freq, cfg->sat_phase,
          cfg->base_val, cfg->val_amp, cfg->val_freq, cfg->val_phase
      );
  }
  
  for(;;){
    frame_count++;
    float time = frame_count * 0.1f;
    
    // すべての球を更新（ループで処理）
    for (int i = 0; i < num_balls; i++) {
        update_ball_radius(&balls[i], time);
        update_ball_color_hsv(&balls[i], time);  // HSV版の色更新
        update_ball_physics(&balls[i], DISPLAY_RADIUS, GRAVITY_STRENGTH, time);
    }
    
    // LEDバッファを黒で初期化
    memset(led, 0, LEDS * 3);
    
    // フレームレート確認用：RGB色がフレームごとに切り替わる描画
    // uint8_t r = 0, g = 0, b = 0;
    // int color_cycle = frame_count % 3;
    // if (color_cycle == 0) {
    //     g = 10;
    // } else if (color_cycle == 1) {
    //     r = 10;
    // } else {
    //     b = 10;
    // }
    
    // // 全LEDを同じ色で塗りつぶし
    // for (int i = 0; i < LEDS; i++) {
    //     led[i * 3 + 0] = g; //g
    //     led[i * 3 + 1] = r; //r
    //     led[i * 3 + 2] = b; //b
    // }
    
    // // すべての球を描画（優先度付き加算モードで描画）- 一時的にコメントアウト
    for (int i = 0; i < num_balls; i++) {
        draw_ball(led, &balls[i], 2);  // mode=2: 優先度付き加算（後描画が優先）
    }
    
    
    // transmit
    if (send_led_data(fd, led) < 0) {
        break;
    }
    
    usleep(3000);
  }
  close(fd);
  return 0;
}
