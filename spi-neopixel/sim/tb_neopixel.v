// tb_neopixel.v - Simple NeoPixel Driver Testbench
`timescale 1ns / 1ps

module tb_neopixel;

    parameter LEDS = 30;
    parameter CLK_HZ = 50_000_000;
    parameter CLK_PERIOD = 20; // 50MHz = 20ns

    // Test signals
    reg i_clk;
    reg i_rst_n;
    reg i_start;
    wire o_busy;
    wire [$clog2(LEDS*3)-1:0] o_rd_addr;
    reg [7:0] i_data;
    wire o_neopixel_out;
    wire o_frame_done;

    // Test memory
    reg [7:0] test_mem [0:LEDS*3-1];

    // DUT
    neopixel_driver #(
        .LEDS(LEDS),
        .CLK_HZ(CLK_HZ)
    ) dut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(i_start),
        .o_busy(o_busy),
        .o_rd_addr(o_rd_addr),
        .i_data(i_data),
        .o_neopixel_out(o_neopixel_out),
        .o_frame_done(o_frame_done)
    );

    // Memory interface
    always @(*) begin
        i_data = test_mem[o_rd_addr];
    end

    // Clock generation
    initial begin
        i_clk = 0;
        forever #(CLK_PERIOD/2) i_clk = ~i_clk;
    end

    // Test sequence
    initial begin
        $dumpfile("tmp/neopixel.vcd");
        $dumpvars(0, tb_neopixel);

        // Initialize
        i_rst_n = 0;
        i_start = 0;

        // Set test data for 30 LEDs
        // Create a simple pattern: Red, Green, Blue, repeating
        for (integer i = 0; i < LEDS; i = i + 1) begin
            case (i % 3)
                0: begin // Red LED
                    test_mem[i*3 + 0] = 8'h55; // R
                    test_mem[i*3 + 1] = i; // G
                    test_mem[i*3 + 2] = 8'h00; // B
                end
                1: begin // Green LED
                    test_mem[i*3 + 0] = 8'h00; // R
                    test_mem[i*3 + 1] = 8'hFF; // G
                    test_mem[i*3 + 2] = i; // B
                end
                2: begin // Blue LED
                    test_mem[i*3 + 0] = i; // R
                    test_mem[i*3 + 1] = 8'h00; // G
                    test_mem[i*3 + 2] = 8'hFF; // B
                end
            endcase
        end

        $display("=== NeoPixel Test Start ===");
        $display("Testing %0d LEDs (%0d bytes)", LEDS, LEDS*3);

        // Reset release
        #100;
        i_rst_n = 1;
        #100;

        // Start transmission
        i_start = 1;
        #20;
        i_start = 0;

        $display("Started transmission...");

        // Wait for completion
        wait(o_frame_done);
        $display("Frame done!");

        wait(!o_busy);
        $display("Transmission complete!");

        #1000;
        $display("=== Test End ===");
        $finish;
    end

    // Timeout
    initial begin
        #50000000; // 50ms (30 LEDs need more time)
        $display("TIMEOUT!");
        $finish;
    end

endmodule
