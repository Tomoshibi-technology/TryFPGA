module neopixel_driver #(
  parameter LEDS = 200,
  parameter CLK_HZ = 50_000_000
)(
    input wire i_clk,
    input wire i_rst_n,

    input wire i_start,
    output reg o_busy,

    output reg o_rd_addr[$clog2(LEDS*3)-1:0],
    input wire [7:0] i_data,

    output reg o_neopixel_out,
    output reg o_frame_done
);

localparam T0H_TCK = CLK_HZ/1_000_000 * 350/1000; // 350ns
localparam T0L_TCK = CLK_HZ/1_000_000 * 800/1000; // 800ns
localparam T1H_TCK = CLK_HZ/1_000_000 * 700/1000; // 700ns
localparam T1L_TCK = CLK_HZ/1_000_000 * 600/1000; // 600ns
localparam RST_TCK = CLK_HZ/1_000_000 * 50_000; // 50us

typedef enum logic [2:0] {
    IDLE,
    HI,
    LO,
    RST,
    DONE
} state_t;

state_t r_state = IDLE;
reg [$clog2(LEDS*3)-1:0] r_pixel_cnt = 0;
reg [$clog2(8*3)-1:0] r_bit_cnt = 0;


endmodule
