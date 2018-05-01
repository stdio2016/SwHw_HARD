module test;
// reference: https://github.com/frobino/axi_custom_ip_tb

reg clock = 1;
reg reset = 0;
reg [5:0] awaddr;
reg awvalid;
reg [31:0] wdata;
reg wvalid;
reg bready;
reg [2:0] awprot = 0;
reg [2:0] arprot = 0;
reg [3:0] wstrb = 15;
wire awready;
wire wready;
wire bvalid;

compute_sad_v2_0 dut(
    .s00_axi_aclk(clock),
    .s00_axi_aresetn(reset),
    .s00_axi_awaddr(awaddr),
    .s00_axi_awvalid(awvalid),
    .s00_axi_wdata(wdata),
    .s00_axi_wvalid(wvalid),
    .s00_axi_bready(bready),
    .s00_axi_awprot(awprot),
    .s00_axi_arprot(arprot),
    .s00_axi_wstrb(wstrb),
    .s00_axi_awready(awready),
    .s00_axi_wready(wready),
    .s00_axi_bvalid(bvalid)
  );

task write;
  input [5:0] addr;
  input [31:0] data;
  begin
    awaddr <= addr<<2;
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
  
initial begin
  repeat (10000) #5 clock = ~clock;
  $finish;
end

integer i, j;
reg [31:0] wri;
initial begin
  @(posedge clock);
  reset <= 1;
  @(posedge clock);
  // write face
  for (i = 0; i < 32; i=i+1) begin
    write(8, i+32);
    for (j = 0; j < 8; j=j+1) begin
      if (i>>2 == j) wri = 1 << ((i-j*4) * 8);
      else wri = 0;
      write(j, wri);
    end
  end
  
  // write group
  for (i = 0; i < 32; i=i+1) begin
    write(8, i);
    for (j = 0; j < 8; j=j+1) begin
      if (i>>2 == j) wri = 1 << ((i-j*4) * 8);
      else wri = 0;
      write(j, wri);
    end
  end
  // write single row
  i = 0;
  write(8, i);
  for (j = 0; j < 8; j=j+1) begin
    if (i>>2 == j) wri = 1 << ((i-j*4) * 8);
    else wri = 0;
    write(j, wri);
  end
  
  // simulate run
  
  write(9, 1);
end

endmodule
