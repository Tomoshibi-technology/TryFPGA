module uart_tx(
  input wire clk,
  input wire rst,
  input wire start,
  input wire [7:0] data_in,
  output reg tx,
  output reg busy
);

localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10;
localparam STOP = 2'b11;

reg [1:0] state;
reg [3:0] bit_count;
reg [7:0] shift_reg;


always @(posedge clk or posedge rst) begin
  busy <= (state != IDLE);
  if(rst) begin
    state <= IDLE;
    tx <= 1'b1;
    busy <= 1'b0;
  end else begin
    case(state)
      IDLE: begin
        if(start) begin // 1bit delay
          state <= START;
          bit_count <= 4'b0000;
          shift_reg <= data_in;
        end
      end
      START: begin
        state <= DATA;
        tx <= 1'b0; // Start bit
      end
      DATA: begin
        tx <= shift_reg[0]; // Transmit LSB first
        shift_reg <= {1'b0, shift_reg[7:1]}; // Shift
        if(bit_count == 4'b0111) begin
          state <= STOP;
        end else begin
          bit_count <= bit_count + 4'b0001;
        end
      end
      STOP: begin
        tx <= 1'b1; // Stop bit
        state <= IDLE;
      end
      default: begin
        state <= IDLE; // Fallback to IDLE state
      end
    endcase
  end
end
endmodule