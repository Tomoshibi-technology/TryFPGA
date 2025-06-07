module tb_uart;
  reg clk;
  reg rst;
  reg start;
  reg [7:0] data_in;
  wire tx;
  wire busy;

  uart_tx uart (
    .clk(clk),
    .rst(rst),
    .start(start),
    .data_in(data_in),
    .tx(tx),
    .busy(busy)
  );

  initial begin
    $dumpfile(`DUMPFILE);
    $dumpvars(0, tb_uart);
  end

  initial begin
    clk = 0;
    forever #2.5 clk = ~clk;
  end

  initial begin
    rst = 1;
    start = 0;
    data_in = 8'b00000011;

    #10 rst = 0;
    #5 start = 1; // Start transmission
    #5 start = 0; // Clear start signal

    #100;

    $finish;
  end

endmodule