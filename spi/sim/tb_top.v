// tb_top.v – SPIテストベンチ
`timescale 1ns / 1ps

`define SIMULATION        // シミュレーション用スイッチ

module tb_top;
    // テストベンチ用クロック・リセット
    reg clk27m  = 0;
    reg rst_n   = 0;

    // SPI 信号
    reg sclk;
    reg cs;
    reg mosi;
    wire miso;

    // テスト用変数を追加
    reg [7:0] test_data;
    integer i;

    // // クロック：27 MHz → 18.518 ns
    // always #18.518 clk27m = ~clk27m;

    // DUT インスタンス
    top dut (
        .clk27m (clk27m),
        .rst_n  (rst_n),
        .sclk   (sclk),
        .cs     (cs),
        .mosi   (mosi),
        .miso   (miso)
    );

    // シミュレーション制御
    initial begin
        // 波形ダンプ
        $dumpfile("tmp/wave.vcd");
        $dumpvars(0, tb_top);

        // 初期化
        sclk = 1;
        cs = 1;
        mosi = 0;
        rst_n = 0;
        #50;
        rst_n = 1;
        #50;

        cs = 0;
        #20;
        // SPI受信テスト (0xB5 = 10110101)
        test_data = 8'hB5;
        // for文を使って8ビット送信 (MSBファースト)
        for (i = 7; i >= 0; i = i - 1) begin
            sclk = 0; 
            mosi = test_data[i];
            #20;
            sclk = 1;
            #20;
        end
        test_data = 8'h10;
        for (i = 7; i >= 0; i = i - 1) begin
            sclk = 0; 
            mosi = test_data[i];
            #20;
            sclk = 1;
            #20;
        end
        
        cs = 1;
        #100;
        
        // シミュレーション終了
        $finish;
    end
endmodule