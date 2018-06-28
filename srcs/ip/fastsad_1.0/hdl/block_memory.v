`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/28 19:49:23
// Design Name: 
// Module Name: block_memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module block_memory
#(
  parameter ADDR_WIDTH = 11,
  parameter DATA_WIDTH = 32
)
(
  input wire clk,
  input wire [ADDR_WIDTH-1:0] rd_addr,
  input wire [ADDR_WIDTH-1:0] wr_addr,
  input wire [DATA_WIDTH-1:0] wr_data,
  input wire wr_en,
  output reg [DATA_WIDTH-1:0] rd_data
);

reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];
always @(posedge clk) begin
  if (wr_en) mem[wr_addr] <= wr_data;
  rd_data <= mem[rd_addr];
end

endmodule
