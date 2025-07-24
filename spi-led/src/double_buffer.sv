/*
各入出力について
  i_clk: クロック
  i_rst_n: リセット (アクティブLOW)

  i_wr_en: 書き込み有効信号
    clk立ち上がり時に1ならば、i_wr_addrとi_wr_dataを使って書き込み
  i_wr_addr: 書き込みアドレス
  i_wr_data: 書き込みデータ
  i_swap: 1フレーム書き込み完了信号 = スワップする

  i_rd_addr: 読み出しアドレス
  o_rd_data: 読み出しデータ
  o_read_frame_valid: 読み出しフレーム有効信号 = スワップ後に1クロック分1になる。
*/

module double_buffer #(
  parameter LEDS = 200,
  parameter ADDR_WIDTH = $clog2(LEDS*3)
)(
  input wire i_clk,
  input wire i_rst_n,

  input wire i_wr_en,
  input wire [ADDR_WIDTH-1:0] i_wr_addr,
  input wire [7:0] i_wr_data,
  input wire i_swap, // 1フレーム書き込み完了通知 = スワップする

  input wire [ADDR_WIDTH-1:0] i_rd_addr,
  output wire [7:0] o_rd_data
  // output wire o_read_frame_valid

);

  reg r_buf_sel = 0; // 0: write A, read B; 1: write B, read A

  reg[7:0] r_bufA[0:LEDS*3-1]/* synthesis syn_ramstyle="block_ram" */;
  reg[7:0] r_bufB[0:LEDS*3-1]/* synthesis syn_ramstyle="block_ram" */;

  // 書き込み
  // always_ff @(posedge i_clk) begin
  //   if(i_wr_en) begin
  //     if (!r_buf_sel) r_bufA[i_wr_addr] <= i_wr_data;
  //     else r_bufB[i_wr_addr] <= i_wr_data;
  //   end
  // end
  always_ff @(posedge i_clk) begin
    if (i_wr_en && (r_buf_sel==0)) r_bufA[i_wr_addr] <= i_wr_data;
  end
  always_ff @(posedge i_clk) begin
    if (i_wr_en && (r_buf_sel==1)) r_bufB[i_wr_addr] <= i_wr_data;
  end

  // 読み出し（遅延1クロック）
  logic [7:0] rdA, rdB;
  always_ff @(posedge i_clk) rdA <= r_bufA[i_rd_addr];
  always_ff @(posedge i_clk) rdB <= r_bufB[i_rd_addr];
  assign o_rd_data = (r_buf_sel==0) ? rdB : rdA;

  // 切り替え
  always_ff @(posedge i_clk)begin
    if(!i_rst_n) r_buf_sel <= 1'b0;
    else if(i_swap) r_buf_sel <= ~r_buf_sel; // toggle buffer selection
  end
endmodule









  // reg [1:0] r_frame_valid = 0;
  // assign o_read_frame_valid = r_frame_valid[1];

  // // read
  // assign o_rd_data = (r_buf_sel==0)? r_bufB[i_rd_addr] : r_bufA[i_rd_addr];

  // // write
  // always @(posedge i_clk) begin
  //   if (!i_rst_n)begin
  //     r_buf_sel <= 0;
  //     r_frame_valid <= 2'b00;
  //   end else begin
  //     if(i_wr_en) begin
  //       if (r_buf_sel == 0) begin
  //         r_bufA[i_wr_addr] <= i_wr_data;
  //       end else begin
  //         r_bufB[i_wr_addr] <= i_wr_data;
  //       end
  //     end

  //     if (i_swap) begin // 1フレーム書き込み完了
  //       r_buf_sel <= ~r_buf_sel; // toggle buffer selection
  //       r_frame_valid <= {r_frame_valid[0], 1'b1}; // 新しいフレームが有効
  //     end else begin
  //       r_frame_valid <= {r_frame_valid[0], 1'b0}; // フレームはまだ有効ではない
  //     end
  //   end
  // end