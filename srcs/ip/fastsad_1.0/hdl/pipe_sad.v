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
  parameter GROUP_WIDTH_BITS = 11,
  parameter FACE_COUNT_BITS = 2
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
  output [GROUP_WIDTH_BITS-1:0] col_out,
// set face
  input face_wr_en,
  input [FACE_COUNT_BITS+FACE_HEIGHT_BITS-1:0] face_wr_row_idx,
  input [FACE_WIDTH_BITS-1:0] face_wr_col_idx,
  input [7:0] face_wr_data,
  input face_select_en,
  input [FACE_COUNT_BITS-1:0] face_select
);

localparam FACE_HEIGHT = 2**FACE_HEIGHT_BITS;
localparam FACE_WIDTH = 2**FACE_WIDTH_BITS;

wire [0:FACE_HEIGHT*8-1] image_col;
wire [0:FACE_WIDTH*8-1] image_rows [0:FACE_HEIGHT];
wire [0:FACE_HEIGHT*FACE_WIDTH*8-1] flattened_image;
wire [0:FACE_HEIGHT*FACE_WIDTH*8-1] flattened_face;
wire [FACE_WIDTH_BITS+FACE_HEIGHT_BITS+8-1:0] sad_result;

wire [GROUP_WIDTH_BITS-1:0] col_in_rot;
wire ready_rot;

reg [1:0] state, state_next;
reg [FACE_HEIGHT_BITS-1:0] face_rd_row_idx;
wire [0:FACE_WIDTH*8-1] face_rd_row;
localparam No_Change = 0;
localparam Changing = 1;
localparam Changing2 = 2;

// pipeline delay = FACE_HEIGHT_BITS
image_rotator #(
  .FACE_HEIGHT_BITS(FACE_HEIGHT_BITS)
) Rotate_It (
  .clock(clock),
  .rotate(row[FACE_HEIGHT_BITS-1:0]+1'b1),
  .img_in(rotated_image),
  .img_out(image_col)
);

pipe_reg #(
  .PIPE_LENGTH(FACE_HEIGHT_BITS),
  .DATA_WIDTH(GROUP_WIDTH_BITS+1)
) Rotate_Pipe (
  .clock(clock),
  .data_in({col_in, ready}),
  .data_out({col_in_rot, ready_rot})
);

generate
genvar si;
for (si = 0; si < FACE_HEIGHT; si = si + 1) begin
  shift_reg #(
    .DATA_WIDTH(8),
    .PIPE_LENGTH(FACE_WIDTH)
  ) Image_regs (
    .clock(clock),
    .enabled({FACE_WIDTH{ready_rot}}),
    .data_in(image_col[si*8 +: 8]),
    .data_out(image_rows[si])
  );
end
endgenerate

shift_reg #(
  .DATA_WIDTH(8*FACE_WIDTH),
  .PIPE_LENGTH(FACE_HEIGHT)
) Face_regs (
  .clock(clock),
  .enabled({FACE_HEIGHT{state == Changing || state == Changing2}}),
  .data_in(face_rd_row),
  .data_out(flattened_face)
);

generate
genvar fi;
for (fi = 0; fi < FACE_HEIGHT; fi = fi + 1) begin
  assign flattened_image[fi*FACE_WIDTH*8 +: FACE_WIDTH*8] = image_rows[fi];
end
endgenerate

// pipeline delay = FACE_WIDTH_BITS + FACE_HEIGHT_BITS + 1
sad #(
  .PIXEL_WIDTH_BITS(FACE_WIDTH_BITS + FACE_HEIGHT_BITS)
) SAD_of_32x32 (
  .clock(clock),
  .image(flattened_image),
  .face(flattened_face),
  .sad_result(sad_result)
);
assign sad_out = sad_result;

pipe_reg #(
  .PIPE_LENGTH(1 + FACE_WIDTH_BITS + FACE_HEIGHT_BITS + 1),
  .DATA_WIDTH(GROUP_WIDTH_BITS+1)
) SAD_Pipe (
  .clock(clock),
  .data_in({col_in_rot, ready_rot}),
  .data_out({col_out, valid})
);

always @(posedge clock) begin
  if (reset == 0) begin
    state <= No_Change;
  end
  else begin
    state <= state_next;
  end
end

always @(*) begin
  case (state)
    No_Change: begin
      state_next = face_select_en ? Changing : No_Change;
    end
    Changing: begin
      state_next = face_rd_row_idx == 0 ? Changing2 : Changing;
    end
    Changing2: state_next = No_Change;
    default: state_next = No_Change;
  endcase
end

always @(posedge clock) begin
  if (state == No_Change)
    face_rd_row_idx <= FACE_HEIGHT-1;
  else if (state == Changing)
    face_rd_row_idx <= face_rd_row_idx - 1;
end

genvar j;
generate
for (j = 0; j < FACE_WIDTH; j = j + 1) begin
  block_memory #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(FACE_COUNT_BITS+FACE_HEIGHT_BITS)
  ) Face_Memory (
    .clk(clock),
    .rd_addr({face_select, face_rd_row_idx}),
    .wr_addr(face_wr_row_idx),
    .wr_data(face_wr_data),
    .wr_en((face_wr_col_idx == FACE_WIDTH-j-1) && face_wr_en),
    .rd_data(face_rd_row[j*8+:8])
  );
end
endgenerate

endmodule
