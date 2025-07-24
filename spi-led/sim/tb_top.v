// tb_top.v – SPI to NeoPixel システムテストベンチ
`timescale 1ns / 1ps

`define SIMULATION

module tb_top;
    reg clk50m = 0;
    reg rst_n = 0;
    reg sclk, cs, mosi;
    wire [7:0] debug_led;
    wire debug_sclk, debug_cs, debug_mosi;

    integer i, j;

    always #10 clk50m = ~clk50m;

    top dut (
        .i_clk50m(clk50m),
        .i_rst_n(rst_n),
        .i_sclk(sclk),
        .i_cs(cs),
        .i_mosi(mosi),
        .o_debug_led(debug_led),
        .o_debug_sclk(debug_sclk),
        .o_debug_cs(debug_cs),
        .o_debug_mosi(debug_mosi)
    );

    // SPIバイト送信
    task spi_send_byte(input [7:0] data);
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                sclk = 0; 
                mosi = data[i];
                #50;
                sclk = 1;
                #50;
            end
        end
    endtask

    // RGB送信
    task send_rgb(input [7:0] r, input [7:0] g, input [7:0] b);
        begin
            spi_send_byte(r);
            spi_send_byte(g);
            spi_send_byte(b);
        end
    endtask

    // シミュレーション制御
    initial begin
        $dumpfile("tmp/wave.vcd");
        $dumpvars(0, tb_top);

        // 初期化
        sclk = 1; cs = 1; mosi = 0; rst_n = 0;
        #100; rst_n = 1; #100;

        // テスト: LEDパターン送信
        cs = 0; #50;
        spi_send_byte(8'h55);  // スタートバイト
        spi_send_byte(8'h5B);
        
        send_rgb(255, 125, 0);   // LED 0: 赤
        send_rgb(0, 255, 125);   // LED 1: 緑
        send_rgb(125, 0, 255);   // LED 2: 青
        
        // 残りのLEDは消灯
        for (j = 3; j < 1200; j = j + 1) begin
            send_rgb(55, 0, 0);
        end
        
        spi_send_byte(8'hAA);  // ストップバイト
        spi_send_byte(8'hAA);  // ストップバイト（2回送信）
        mosi = 0; cs = 1;

        #20000; // 送信後の待機時間
        // テスト: LEDパターン送信


        cs = 0; #50;
        spi_send_byte(8'h55);  // スタートバイト
        spi_send_byte(8'h5B);
                
        for (j = 0; j < 30; j = j + 1) begin
            send_rgb(8'h77, 8'h00, 8'h11); // 全LEDを赤に点灯
        end
        
        spi_send_byte(8'hAA);  // ストップバイト
        spi_send_byte(8'hAA);  // ストップバイト（2回送信）
        mosi = 0; cs = 1;

        
        #2000000;
        
        $finish;
    end

endmodule