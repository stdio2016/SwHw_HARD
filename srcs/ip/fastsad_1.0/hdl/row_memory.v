// created by Yi-Feng Chen
// Because Vivado has problem inferring block RAM from my design
// I have to write a block RAM description

module row_memory #(
    parameter integer MY_BUF_ADDR_WIDTH = 11
  )
  (
    input wire clk,
    input wire [MY_BUF_ADDR_WIDTH-3:0] rd_addr,
    input wire [MY_BUF_ADDR_WIDTH-3:0] wr_addr,
    input wire [31:0] wr_data,
    input wire wr_en,
    output reg [31:0] rd_data
  );
  
reg [31:0] mem [0:(2**MY_BUF_ADDR_WIDTH)/4-1];
always @(posedge clk) begin
  if (wr_en) mem[wr_addr] <= wr_data;
  rd_data <= mem[rd_addr];
end

endmodule //row_memory
