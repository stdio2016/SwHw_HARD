`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/28 17:52:36
// Design Name: 
// Module Name: pipe_reg
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
module pipe_reg
#(
  parameter PIPE_LENGTH = 4,
  parameter DATA_WIDTH = 8
)
(
  input clock,
  input [DATA_WIDTH-1:0] data_in,
  output [DATA_WIDTH-1:0] data_out
);

reg [DATA_WIDTH-1:0] stage [0:PIPE_LENGTH-1];

always @(posedge clock) begin
  stage[0] <= data_in;
end

genvar i;
generate
for (i = 1; i < PIPE_LENGTH; i = i + 1) begin
  always @(posedge clock) begin
    stage[i] <= stage[i-1];
  end
end
endgenerate

assign data_out = stage[PIPE_LENGTH-1];

endmodule
