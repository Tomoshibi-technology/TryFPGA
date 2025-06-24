// ============================================================
// tb_top.v – iverilog 用テストベンチ
// ============================================================
`timescale 1ns / 1ps

`define SIMULATION        // シミュレーション用スイッチ

module tb_top;
    // テストベンチ用クロック・リセット
    reg clk27m  = 0;
    reg rst_n   = 0;

    // DUT 出力
    wire led_out;

    // クロック：27 MHz → 18.518 ns
    always #18.518 clk27m = ~clk27m;

    // DUT インスタンス
    top dut (
        .clk27m (clk27m),
        .rst_n  (rst_n),
        .led_out(led_out)
    );

    // シミュレーション制御
    initial begin
        // 波形ダンプ
        $dumpfile("tmp/wave.vcd");
        $dumpvars(0, tb_top);

        // リセット解除
        #100 rst_n = 1;

        // 数サイクル観測したら終了
        #100_000 $finish;
    end
endmodule
