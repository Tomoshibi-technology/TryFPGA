/*
*/

module double_buffer #(
  parameter LEDS = 30,
  parameter ADDR_WIDTH = $clog2(LEDS*3)
)(
  input wire i_clk,
  input wire i_rst_n,

  input wire i_wr_en,
  input wire [ADDR_WIDTH-1:0] i_wr_addr,
  input wire [7:0] i_wr_data,
  input wire i_write_frame_done, // 1フレーム書き込み完了通知 = スワップする

  input wire [ADDR_WIDTH-1:0] i_rd_addr,
  output wire [7:0] o_rd_data,
  output wire o_read_frame_valid

);

  reg[7:0] r_bufA[0:LEDS*3-1];
  reg[7:0] r_bufB[0:LEDS*3-1];

  reg r_buf_sel = 0; // 0: write A, read B; 1: write B, read A

  reg [1:0] r_frame_valid = 0;
  assign o_read_frame_valid = r_frame_valid[1];

  // read
  assign o_rd_data = (r_buf_sel==0)? r_bufB[i_rd_addr] : r_bufA[i_rd_addr];

  // write
  always @(posedge i_clk) begin
    if (!i_rst_n)begin
      r_buf_sel <= 0;
      r_frame_valid <= 2'b00;
    end else begin
      if(i_wr_en) begin
        if (r_buf_sel == 0) begin
          r_bufA[i_wr_addr] <= i_wr_data;
        end else begin
          r_bufB[i_wr_addr] <= i_wr_data;
        end
      end

      if (i_write_frame_done) begin // 1フレーム書き込み完了
        r_buf_sel <= ~r_buf_sel; // toggle buffer selection
        r_frame_valid <= {r_frame_valid[0], 1'b1}; // 新しいフレームが有効
      end else begin
        r_frame_valid <= {r_frame_valid[0], 1'b0}; // フレームはまだ有効ではない
      end
    end
  end
endmodule