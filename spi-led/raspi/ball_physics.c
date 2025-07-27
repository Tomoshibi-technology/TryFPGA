#include "ball_physics.h"
#include "neopixel_cordinates.h"
#include <math.h>
#include <string.h>

// HSVからRGBへの変換関数
void hsv_to_rgb(float h, float s, float v, uint8_t *r, uint8_t *g, uint8_t *b) {
    // 色相を0-360の範囲に正規化
    while (h < 0) h += 360.0f;
    while (h >= 360) h -= 360.0f;
    
    // 彩度と明度を0-1の範囲にクランプ
    if (s < 0) s = 0;
    if (s > 1) s = 1;
    if (v < 0) v = 0;
    if (v > 1) v = 1;
    
    float c = v * s;
    float x = c * (1.0f - fabsf(fmodf(h / 60.0f, 2.0f) - 1.0f));
    float m = v - c;
    
    float r_temp, g_temp, b_temp;
    
    if (h < 60) {
        r_temp = c; g_temp = x; b_temp = 0;
    } else if (h < 120) {
        r_temp = x; g_temp = c; b_temp = 0;
    } else if (h < 180) {
        r_temp = 0; g_temp = c; b_temp = x;
    } else if (h < 240) {
        r_temp = 0; g_temp = x; b_temp = c;
    } else if (h < 300) {
        r_temp = x; g_temp = 0; b_temp = c;
    } else {
        r_temp = c; g_temp = 0; b_temp = x;
    }
    
    *r = (uint8_t)((r_temp + m) * 255.0f);
    *g = (uint8_t)((g_temp + m) * 255.0f);
    *b = (uint8_t)((b_temp + m) * 255.0f);
}

// 球の物理計算を更新
void update_ball_physics(Ball *ball, float display_radius, float gravity_strength, float time) {
    // 重力のような効果を追加（中心に向かう微弱な力）
    float distance_from_center = sqrtf(ball->x * ball->x + ball->y * ball->y);
    if (distance_from_center > 0.1f) {
        ball->velocity_x -= gravity_strength * ball->x / distance_from_center;
        ball->velocity_y -= gravity_strength * ball->y / distance_from_center;
    }
    
    // 球の位置を更新
    ball->x += ball->velocity_x;
    ball->y += ball->velocity_y;
    
    // 壁との衝突判定と反射
    distance_from_center = sqrtf(ball->x * ball->x + ball->y * ball->y);
    float collision_distance = display_radius - ball->radius;
    
    if (distance_from_center >= collision_distance) {
        ball->collision_count++;
        
        // 壁に衝突した場合、反射
        float normal_x = ball->x / distance_from_center;
        float normal_y = ball->y / distance_from_center;
        
        // 速度ベクトルを法線方向に反射
        float dot_product = ball->velocity_x * normal_x + ball->velocity_y * normal_y;
        ball->velocity_x -= 2.0f * dot_product * normal_x;
        ball->velocity_y -= 2.0f * dot_product * normal_y;
        
        // 反射時にランダムな回転要素を追加
        float rotation_angle = 0.3f * sinf(ball->collision_count * 0.7f);
        float cos_rot = cosf(rotation_angle);
        float sin_rot = sinf(rotation_angle);
        
        float new_vx = ball->velocity_x * cos_rot - ball->velocity_y * sin_rot;
        float new_vy = ball->velocity_x * sin_rot + ball->velocity_y * cos_rot;
        ball->velocity_x = new_vx;
        ball->velocity_y = new_vy;
        
        // 速度に変化を加える
        float speed_factor = 0.95f + 0.1f * sinf(ball->collision_count * 0.5f);
        ball->velocity_x *= speed_factor;
        ball->velocity_y *= speed_factor;
        
        // 球を壁の内側に戻す
        ball->x = normal_x * collision_distance;
        ball->y = normal_y * collision_distance;
    }
}

// 球を描画（複数モード対応）
void draw_ball(uint8_t *led, const Ball *ball, int mode) {
    for (int i = 0; i < 1200; i++) {  // LEDS定数をハードコード
        const NeoPixelCoord* coord = get_neopixel_coord(i);
        if (coord != NULL) {
            // 座標を実際の値に変換（mm単位）
            float pixel_x = COORD_TO_FLOAT(coord->x);
            float pixel_y = COORD_TO_FLOAT(coord->y);
            
            // 中心からの距離を計算
            float distance = sqrtf((pixel_x - ball->x) * (pixel_x - ball->x) + 
                                 (pixel_y - ball->y) * (pixel_y - ball->y));
            
            // 球の内部にある場合、距離に応じて明度を調整
            if (distance <= ball->radius) {
                float distance_ratio = distance / ball->radius;
                // より急激な減衰で中心の明るい範囲を狭く
                float intensity = (1.0f - distance_ratio) * (1.0f - distance_ratio); // 二乗で急激な減衰
                
                if (mode == 1) {
                    // 加算合成モード（既存の値に加算）
                    int new_r = led[i * 3 + 0] + (int)(ball->r * intensity);
                    int new_g = led[i * 3 + 1] + (int)(ball->g * intensity);
                    int new_b = led[i * 3 + 2] + (int)(ball->b * intensity);
                    
                    led[i * 3 + 0] = (new_r > 255) ? 255 : (uint8_t)new_r;
                    led[i * 3 + 1] = (new_g > 255) ? 255 : (uint8_t)new_g;
                    led[i * 3 + 2] = (new_b > 255) ? 255 : (uint8_t)new_b;
                } else if (mode == 2) {
                    // 優先度付き加算モード（後描画が優先、既存色を少し減衰させて加算）
                    uint8_t current_r = led[i * 3 + 0];
                    uint8_t current_g = led[i * 3 + 1];
                    uint8_t current_b = led[i * 3 + 2];
                    
                    // 現在の色を70%に減衰させてから新しい色を加算
                    float decay_factor = 0.7f;
                    int new_r = (int)(current_r * decay_factor) + (int)(ball->r * intensity);
                    int new_g = (int)(current_g * decay_factor) + (int)(ball->g * intensity);
                    int new_b = (int)(current_b * decay_factor) + (int)(ball->b * intensity);
                    
                    led[i * 3 + 0] = (new_r > 255) ? 255 : (uint8_t)new_r;
                    led[i * 3 + 1] = (new_g > 255) ? 255 : (uint8_t)new_g;
                    led[i * 3 + 2] = (new_b > 255) ? 255 : (uint8_t)new_b;
                } else {
                    // 通常モード（上書き）
                    led[i * 3 + 0] = (uint8_t)(ball->r * intensity);   // Red
                    led[i * 3 + 1] = (uint8_t)(ball->g * intensity);   // Green  
                    led[i * 3 + 2] = (uint8_t)(ball->b * intensity);   // Blue
                }
            } else if (mode == 0) {
                // 球の外部は消灯（通常モードのみ）
                led[i * 3 + 0] = 0;
                led[i * 3 + 1] = 0;
                led[i * 3 + 2] = 0;
            }
        }
    }
}

// 球の半径を中心からの距離に基づいて更新
void update_ball_radius(Ball *ball, float time) {
    // 中心からの距離を計算
    float distance_from_center = sqrtf(ball->x * ball->x + ball->y * ball->y);
    
    // 距離に基づく半径スケーリング（控えめな変化）
    float max_distance = 90.0f; // DISPLAY_RADIUSと同じ値
    float distance_factor = 1.0f - 0.3f * (distance_from_center / max_distance); // 最大30%の変化に抑制
    distance_factor = (distance_factor < 0.7f) ? 0.7f : distance_factor; // 最小70%のサイズは保持
    
    // 基本の半径変化（時間による振動）
    float base_radius_variation = ball->base_radius + ball->radius_amplitude * sinf(time * ball->radius_frequency + ball->radius_phase);
    
    // 距離による効果を適用
    ball->radius = base_radius_variation * distance_factor;
}

// 球の色をHSVで汎用的に更新
void update_ball_color_hsv(Ball *ball, float time) {
    // HSV値を時間に基づいて更新
    ball->h = ball->base_hue + ball->hue_amplitude * sinf(time * ball->hue_frequency + ball->hue_phase);
    ball->s = ball->base_saturation + ball->saturation_amplitude * sinf(time * ball->saturation_frequency + ball->saturation_phase);
    ball->v = ball->base_value + ball->value_amplitude * sinf(time * ball->value_frequency + ball->value_phase);
    
    // 彩度と明度を0-1の範囲にクランプ
    if (ball->s < 0) ball->s = 0;
    if (ball->s > 1) ball->s = 1;
    if (ball->v < 0) ball->v = 0;
    if (ball->v > 1) ball->v = 1;
    
    // HSVからRGBに変換
    hsv_to_rgb(ball->h, ball->s, ball->v, &ball->r, &ball->g, &ball->b);
}
