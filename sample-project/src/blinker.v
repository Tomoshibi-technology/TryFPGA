// ============================================================
// blinker.v  – 汎用トグル Blinker
// ============================================================
module blinker #(
    parameter CNT_MAX = 10
)(
    input  wire clk,
    input  wire rst_n,
    output reg  q_out
);
    reg [$clog2(CNT_MAX+1)-1:0] cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt   <= 0;
            q_out <= 1'b0;
        end else begin
            if (cnt == CNT_MAX) begin
                cnt   <= 0;
                q_out <= ~q_out;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
