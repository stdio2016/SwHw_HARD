`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/21 17:29:00
// Design Name: 
// Module Name: pipe_sad
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


module pipe_sad #(
  parameter FACE_HEIGHT_BITS = 5,
  parameter FACE_WIDTH_BITS = 5,
  parameter GROUP_WIDTH_BITS = 11
)
(
  input clock,
  input reset,
  input [0:FACE_HEIGHT*8-1] rotated_image,
  input [FACE_HEIGHT_BITS-1:0] row,
  input ready,
  input [GROUP_WIDTH_BITS-1:0] col_in,
  output [31:0] sad_out,
  output valid,
  output [GROUP_WIDTH_BITS-1:0] col_out
);

localparam FACE_HEIGHT = 2**FACE_HEIGHT_BITS;

wire [0:FACE_HEIGHT*8-1] image_col;

// pipeline delay = FACE_HEIGHT_BITS
image_rotator #(
  .FACE_HEIGHT_BITS(FACE_HEIGHT_BITS)
) Rotate_It (
  .clock(clock),
  .rotate(row[FACE_HEIGHT_BITS-1:0]),
  .img_in(rotated_image),
  .img_out(image_col)
);

// pipeline delay = FACE_WIDTH_BITS + 1
genvar i;
generate
for (i = 0; i < FACE_HEIGHT; i = i + 1) begin
  sad #(
    .FACE_WIDTH_BITS(FACE_WIDTH_BITS)
  ) SAD_For_Row (
    .clock(clock),
    .image(image_col[i*8 +: 8]),
    .face(),
    .move_image(),
    .move_face(),
    .sad_result()
  );
end
endgenerate

endmodule
