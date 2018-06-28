`timescale 1ns / 1ps

module test;
// reference: https://github.com/frobino/axi_custom_ip_tb
parameter integer C_S_AXI_ADDR_WIDTH	= 6;

reg clock = 1;
reg reset = 0;
reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr;
reg awvalid;
reg [31:0] wdata;
reg wvalid;
reg bready;

reg [C_S_AXI_ADDR_WIDTH-1:0] araddr;
reg arvalid;
reg rready;

reg [2:0] awprot = 0;
reg [2:0] arprot = 0;
reg [3:0] wstrb = 15;
wire awready;
wire wready;
wire bvalid;
wire [1:0] bresp;

wire arready;
wire [31:0] rdata;
wire [1:0] rresp;
wire rvalid;

// for fake memory
wire [31:0] m_awaddr;
wire [7:0] m_awlen;
wire [2:0] m_awsize;
wire m_awvalid;
wire m_awready;
wire [31:0] m_wdata;
wire [3:0] m_wstrb;
wire m_wlast;
wire m_wvalid;
wire m_wready;
wire [1:0] m_bresp;
wire m_bvalid;
wire m_bready;
wire [31:0] m_araddr;
wire [7:0] m_arlen;
wire [2:0] m_arsize;
wire m_arvalid;
wire m_arready;
wire [31:0] m_rdata;
wire [1:0] m_rresp;
wire m_rlast;
wire m_rvalid;
wire m_rready;

  fastsad_v1_0 #(
    .C_M00_AXI_BURST_LEN(64)
  ) dut (
    .s00_axi_aclk(clock),
    .s00_axi_aresetn(reset),
    .s00_axi_awaddr(awaddr),
    .s00_axi_awprot(awprot), // unused
    .s00_axi_awvalid(awvalid),
    .s00_axi_awready(awready),
    .s00_axi_wdata(wdata),
    .s00_axi_wstrb(wstrb),
    .s00_axi_wvalid(wvalid),
    .s00_axi_wready(wready),
    .s00_axi_bresp(bresp), // unused output
    .s00_axi_bvalid(bvalid),
    .s00_axi_bready(bready),
    .s00_axi_araddr(araddr),
    .s00_axi_arprot(arprot), // unused
    .s00_axi_arvalid(arvalid),
    .s00_axi_arready(arready),
    .s00_axi_rdata(rdata),
    .s00_axi_rresp(rresp),
    .s00_axi_rvalid(rvalid),
    .s00_axi_rready(rready),
    
    .m00_axi_aclk(clock),
    .m00_axi_aresetn(reset),
    .m00_axi_awaddr(m_awaddr),
    .m00_axi_awlen(m_awlen),
    .m00_axi_awsize(m_awsize),
    .m00_axi_awvalid(m_awvalid),
    .m00_axi_awready(m_awready),
    .m00_axi_wdata(m_wdata),
    .m00_axi_wstrb(m_wstrb),
    .m00_axi_wlast(m_wlast),
    .m00_axi_wvalid(m_wvalid),
    .m00_axi_wready(m_wready),
    .m00_axi_bresp(m_bresp),
    .m00_axi_bvalid(m_bvalid),
    .m00_axi_bready(m_bready),
    .m00_axi_araddr(m_araddr),
    .m00_axi_arlen(m_arlen),
    .m00_axi_arsize(m_arsize),
    .m00_axi_arvalid(m_arvalid),
    .m00_axi_arready(m_arready),
    .m00_axi_rdata(m_rdata),
    .m00_axi_rresp(m_rresp),
    .m00_axi_rlast(m_rlast),
    .m00_axi_rvalid(m_rvalid),
    .m00_axi_rready(m_rready)
  );

  fake_ram fmem(
      .s_axi_aclk(clock),
      .s_axi_aresetn(reset),
      .s_axi_awaddr(m_awaddr),
      .s_axi_awlen(m_awlen),
      .s_axi_awsize(m_awsize),
      .s_axi_awvalid(m_awvalid),
      .s_axi_awready(m_awready),
      .s_axi_wdata(m_wdata),
      .s_axi_wstrb(m_wstrb),
      .s_axi_wlast(m_wlast),
      .s_axi_wvalid(m_wvalid),
      .s_axi_wready(m_wready),
      .s_axi_bresp(m_bresp),
      .s_axi_bvalid(m_bvalid),
      .s_axi_bready(m_bready),
      .s_axi_araddr(m_araddr),
      .s_axi_arlen(m_arlen),
      .s_axi_arsize(m_arsize),
      .s_axi_arvalid(m_arvalid),
      .s_axi_arready(m_arready),
      .s_axi_rdata(m_rdata),
      .s_axi_rresp(m_rresp),
      .s_axi_rlast(m_rlast),
      .s_axi_rvalid(m_rvalid),
      .s_axi_rready(m_rready)
    );

task write;
  input [31:0] addr;
  input [31:0] data;
  begin
    awaddr <= addr;
    wdata <= data;
    awvalid <= 1;
    wvalid <= 1;
    bready <= 1;
    while (!(awready && wready)) @(posedge clock);
    while (!bvalid) @(posedge clock);
    awvalid <= 0;
    wvalid <= 0;
    bready <= 1;
    while (bvalid) @(posedge clock);
    bready <= 0;
    @(posedge clock);
  end
endtask

task read;
  input [31:0] addr;
  output reg [31:0] data;
  begin
    araddr <= addr;
    arvalid <= 1;
    rready <= 1;
    while (!(arready)) @(posedge clock);
    arvalid <= 0;
    while (!(rvalid)) @(posedge clock);
    data = rdata;
    while (rvalid) @(posedge clock);
    rready <= 0;
    @(posedge clock);
  end
endtask

initial begin
  repeat (2400000) #5 clock = ~clock;
  $finish;
end

integer ans;
integer i;
initial begin
  @(posedge clock);
  reset <= 1;
  @(posedge clock);
  write(1*4, 1);
  write(2*4, 1024);
  write(3*4, 1920*1080);
  write(5*4, 0);
  write(6*4, 0);
  write(0*4, 1);
  read(0*4, ans);
  while (ans != 0) read(0*4, ans);
  
  for (i = 0; i < 100; i=i+1) begin
    write(1*4, 3);
    write(2*4, 64);
    write(3*4, 1920*i);
    write(5*4, i);
    write(6*4, 0);
    write(0*4, 1);
    read(0*4, ans);
    while (ans != 0) read(0*4, ans);
    read(8*4, ans);
    $display("row %d min_sad=%d", i, ans);
    read(9*4, ans);
    $display("at %d", ans);
  end
  $display("Finish!!");
  $finish;
end

endmodule
