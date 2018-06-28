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
  parameter PIXEL_WIDTH_BITS = 10
)
(
  input clock,
// actually it is input [7:0] face [0:PIXEL_WIDTH];
// however, Verilog doesn't support this
  input [0:PIXEL_WIDTH*8-1] face,
  input [0:PIXEL_WIDTH*8-1] image,
  output [PIXEL_WIDTH_BITS+8-1:0] sad_result
);

localparam PIXEL_WIDTH = 2**PIXEL_WIDTH_BITS;

// absolute difference
reg [0:PIXEL_WIDTH*8-1] ad;

integer i;
always @(posedge clock) begin
  for (i = 0; i < PIXEL_WIDTH; i = i + 1) begin
    if (face[i*8+:8] > image[i*8+:8]) begin
      ad[i*8+:8] <= face[i*8+:8] - image[i*8+:8];
    end
    else begin
      ad[i*8+:8] <= image[i*8+:8] - face[i*8+:8];
    end
  end
end

adder_tree #(
  .TREE_HEIGHT(PIXEL_WIDTH_BITS),
  .DATA_WIDTH(8)
) AT (
  .clock(clock),
  .data_in(ad),
  .sum(sad_result)
);

endmodule
