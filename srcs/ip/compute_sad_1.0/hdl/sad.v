`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Yi-Feng Chen
// 
// Create Date: 2018/04/10 10:06:06
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


module sad(
    input clock,
    input [0:32*8-1] face,
    input [0:32*8-1] group,
    output reg [31:0] sad_result,
    input start,
    output finish
    );

wire[7:0] facePix[0:31];
wire[7:0] groupPix[0:31];
generate
    genvar i;
    for (i = 0; i < 32; i = i + 1) begin
        assign facePix[i] = face[i*8 +: 8];
        assign groupPix[i] = group[i*8 +: 8];
    end
endgenerate

integer j;
reg [8:0] diff [0:32-1];
reg [7:0] ad [0:32-1];
reg [16:0] sum1 [0:8-1];
reg [16:0] sum2 [0:2-1];
reg finishStage[0:4];
always @(posedge clock) begin
    for (j = 0; j < 32; j = j + 1) begin : stage1
        diff[j] = {1'b0, facePix[j]} - {1'b0, groupPix[j]};
        ad[j] <= diff[j][8] ? -diff[j] : diff[j]; // ad[j] = abs(diff[j])
    end : stage1
    finishStage[1] <= start;
    
    for (j = 0; j < 8; j = j + 1) begin : stage2
        sum1[j] <= ad[j*4] + ad[j*4+1] + ad[j*4+2] + ad[j*4+3];
    end : stage2
    finishStage[2] <= ~start & finishStage[1];

    for (j = 0; j < 2; j = j + 1) begin : stage3
        sum2[j] <= sum1[j*4] + sum1[j*4+1] + sum1[j*4+2] + sum1[j*4+3];
    end : stage3
    finishStage[3] <= ~start & finishStage[2];
    
    sad_result <= sum2[0] + sum2[1];
    finishStage[4] <= ~start & finishStage[3];
end
assign finish = finishStage[4];

endmodule
