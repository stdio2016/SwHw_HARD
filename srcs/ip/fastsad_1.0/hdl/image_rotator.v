`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/21 20:45:19
// Design Name: 
// Module Name: image_rotator
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


module image_rotator #(
  parameter FACE_HEIGHT_BITS = 5
)
(
  input clock,
  input [FACE_HEIGHT_BITS-1:0] rotate,
  // img_in and img_out are actually arrays of size 8 * FACE_HEIGHT
  // reg [7:0] img_in [0:FACE_HEIGHT];
  input [0:FACE_HEIGHT*8-1] img_in,
  output [0:FACE_HEIGHT*8-1] img_out
);

localparam FACE_HEIGHT = 2**FACE_HEIGHT_BITS;

reg [0:FACE_HEIGHT*8-1] stage [0:FACE_HEIGHT_BITS];
reg [FACE_HEIGHT_BITS-1:0] rotate_stage [0:FACE_HEIGHT_BITS];

always @(*) begin
  stage[0] = img_in;
  rotate_stage[0] = rotate;
end

genvar i;
generate
for (i = 0; i < FACE_HEIGHT_BITS; i = i + 1) begin
  localparam shift_cnt = 8 * (2**i);
  always @(posedge clock) begin
    rotate_stage[i+1] <= rotate_stage[i];
    if (rotate_stage[i][i]) begin
      stage[i+1] <= {
        stage[i][shift_cnt:FACE_HEIGHT*8-1],
        stage[i][0:shift_cnt-1]
      };
    end
    else begin
      stage[i+1] <= stage[i];
    end
  end
end
endgenerate

assign img_out = stage[FACE_HEIGHT_BITS];

endmodule
