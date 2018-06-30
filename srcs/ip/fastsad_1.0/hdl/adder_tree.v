`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/28 15:07:42
// Design Name: 
// Module Name: adder_tree
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


module adder_tree
#(
  parameter TREE_HEIGHT = 5,
  parameter DATA_WIDTH = 8
)
(
  input clock,
  input [0:DATA_WIDTH*DATA_SIZE-1] data_in,
  output [OUTPUT_WIDTH-1:0] sum
);

localparam DATA_SIZE = 2**TREE_HEIGHT;
localparam OUTPUT_WIDTH = DATA_WIDTH + TREE_HEIGHT;

reg [OUTPUT_WIDTH-1:0] sum_heap [0:DATA_SIZE-1]; 

integer i;
always @(posedge clock) begin
  for (i = 0; i < DATA_SIZE/2; i = i + 1) begin
    sum_heap[DATA_SIZE/2+i] <=
        data_in[DATA_WIDTH*(i*2) +: DATA_WIDTH]
      + data_in[DATA_WIDTH*(i*2+1) +: DATA_WIDTH];
  end
end

integer j;
always @(posedge clock) begin
  for (j = 1; j < DATA_SIZE/2; j = j + 1) begin
    sum_heap[j] <= sum_heap[j*2] + sum_heap[j*2+1];
  end
end

assign sum = sum_heap[1];

endmodule
