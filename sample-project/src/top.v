// ============================================================
// top.v  – Tang Nano 用 LED ブリンカ（27 MHz → 1 Hz）
// ============================================================

module top (
    input  wire clk27m,    // Tang Nano 内蔵 27 MHz クロック
    input  wire rst_n,     // 非同期リセット（Low Active）
    output wire led_out    // LED 出力
);

    //----------------------------------------------------------
    // パラメータ
    //----------------------------------------------------------
    localparam CLK_FREQ_HZ = 27_000_000;   // 27 MHz
    localparam BLINK_HZ    = 1;            // 1 Hz で点滅
    localparam CNT_MAX     = 10; //CLK_FREQ_HZ / (2*BLINK_HZ) - 1; // 1 Hz 点滅のためのカウンタ最大値

    //----------------------------------------------------------
    // インスタンス：1 bit トグル FF
    //----------------------------------------------------------
    blinker #(
        .CNT_MAX(CNT_MAX)
    ) u_blinker (
        .clk (clk27m),
        .rst_n(rst_n),
        .q_out(led_out)
    );

endmodule
