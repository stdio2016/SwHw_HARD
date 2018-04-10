`timescale 1ns/0.1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Yi-Feng Chen
// 
// Create Date: 2018/04/10 20:54:29
// Design Name: 
// Module Name: test_sad
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


module test_sad(

    );
    
    wire [0:32*8-1] faceW;
    wire [0:32*8-1] groupW;
    reg [7:0] face [0:31];
    reg [7:0] group [0:31];
    wire [31:0] result;
    reg clk;
    reg start;
    wire finish;
    sad UT(
        .face(faceW),
        .group(groupW),
        .start(start),
        .finish(finish),
        .sad_result(result),
        .clock(clk)
    );
    
    genvar gg;
    for (gg = 0; gg < 32; gg = gg+1) begin
        assign faceW[gg*8 +: 8] = face[gg];
        assign groupW[gg*8 +: 8] = group[gg];
    end
    
    initial begin
        clk = 1;
        repeat(100) #5 clk = ~clk;
    end
    
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            face[i] <= 0;
            group[i] <= 0;
        end
        start <= 0;
        #10
        
        for (i = 0; i < 32; i = i + 1) begin
            face[i] <= 3**i;
            group[i] <= 5**i;
        end
        start <= 1;
    end
endmodule
