`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/28 17:22:55
// Design Name: 
// Module Name: shift_reg
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

// this module is just for fun
module shift_reg
#(
  parameter PIPE_LENGTH = 4,
  parameter DATA_WIDTH = 8
)
(
  input clock,
  input [0:PIPE_LENGTH-1] enabled,
  input [DATA_WIDTH-1:0] data_in,
  output [0:PIPE_LENGTH*DATA_WIDTH-1] data_out
);

reg [DATA_WIDTH-1:0] stage [0:PIPE_LENGTH-1];

always @(posedge clock) begin
  if (enabled[0] == 0) stage[0] <= stage[0];
  else stage[0] <= data_in;
end

assign data_out[0:DATA_WIDTH-1] = stage[0];

genvar i;
generate
for (i = 1; i < PIPE_LENGTH; i = i + 1) begin
  always @(posedge clock) begin
    if (enabled[i] == 0) stage[i] <= stage[i];
    else stage[i] <= stage[i-1];
  end

  assign data_out[i*DATA_WIDTH +: DATA_WIDTH] = stage[i];
end
endgenerate

endmodule
