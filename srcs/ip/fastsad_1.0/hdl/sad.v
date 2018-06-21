`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/21 23:20:48
// Design Name: 
// Module Name: sad
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


module sad
#(
  parameter FACE_WIDTH_BITS = 5
)
(
  input clock,
  input [7:0] face,
  input move_face,
  input [7:0] image,
  input move_image,
  output [FACE_WIDTH_BITS+8-1:0] sad_result
);
endmodule
