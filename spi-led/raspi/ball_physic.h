#ifndef BALL_PHYSICS_H
#define BALL_PHYSICS_H

#include <stdint.h>

// 球の構造体
typedef struct {
    float x, y;                    // 位置
    float velocity_x, velocity_y;  // 速度
    float radius;                  // 半径
    uint8_t r, g, b;              // RGB色（計算結果）
    float h, s, v;                // HSV色（実際に使用）
    unsigned int collision_count;  // 衝突回数
    
    // パラメーター（各球で異なる値を設定可能）
    float base_radius;             // 基本半径
    float radius_amplitude;        // 半径変化の振幅
    float radius_frequency;        // 半径変化の周波数
    float radius_phase;            // 半径変化の位相
    
    // HSV色管理パラメーター
    float base_hue;                // 基本色相 (0-360)
    float hue_amplitude;           // 色相変化の振幅
    float hue_frequency;           // 色相変化の周波数
    float hue_phase;               // 色相変化の位相
    
    float base_saturation;         // 基本彩度 (0.0-1.0)
    float saturation_amplitude;    // 彩度変化の振幅
    float saturation_frequency;    // 彩度変化の周波数
    float saturation_phase;        // 彩度変化の位相
    
    float base_value;              // 基本明度 (0.0-1.0)
    float value_amplitude;         // 明度変化の振幅
    float value_frequency;         // 明度変化の周波数
    float value_phase;             // 明度変化の位相
} Ball;

// 球の物理計算関数
void update_ball_physics(Ball *ball, float display_radius, float gravity_strength, float time);

// 球の描画関数
// mode: 0=上書き, 1=加算合成, 2=優先度付き加算（後描画が優先）
void draw_ball(uint8_t *led, const Ball *ball, int mode);

// 汎用的な更新関数
void update_ball_radius(Ball *ball, float time);
void update_ball_color_hsv(Ball *ball, float time);

// HSV to RGB変換関数
void hsv_to_rgb(float h, float s, float v, uint8_t *r, uint8_t *g, uint8_t *b);

#endif // BALL_PHYSICS_H
