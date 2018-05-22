// this is for simulation only

module fake_ram #
  (
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 32
  )
  (
    input wire  s_axi_aclk,
		input wire  s_axi_aresetn,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
    input wire [7 : 0] s_axi_awlen,
    input wire [2 : 0] s_axi_awsize,
		//input wire [2 : 0] s_axi_awprot,
		input wire  s_axi_awvalid,
		output reg  s_axi_awready,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
    input wire  s_axi_wlast,
		input wire  s_axi_wvalid,
		output reg  s_axi_wready,
		output reg [1 : 0] s_axi_bresp,
		output reg  s_axi_bvalid,
		input wire  s_axi_bready,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
    input wire [7 : 0] s_axi_arlen,
    input wire [2 : 0] s_axi_arsize,
		//input wire [2 : 0] s_axi_arprot,
		input wire  s_axi_arvalid,
		output reg  s_axi_arready,
		output reg [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
		output reg [1 : 0] s_axi_rresp,
    output reg s_axi_rlast,
		output reg  s_axi_rvalid,
		input wire  s_axi_rready
  );

reg [31:0] mem[0:1023];
reg [31:0] raddr;
reg [8:0] rburst;
reg [2:0] delay;
wire yes;
assign yes = delay == 0;

reg [31:0] waddr;
reg [8:0] wburst;
reg [2:0] wdelay;
wire yes2;
assign yes2 = wdelay == 0 && s_axi_wvalid;

// fill pattern in memory
integer i;
initial for (i = 0; i < 1024; i = i+1) begin
  mem[i] = i*4 * 100;
end

// get read address
always @(posedge s_axi_aclk) begin
  if (s_axi_aresetn == 0) begin
    raddr <= 0;
    s_axi_arready <= 0;
    rburst <= 0;
  end
  else begin
    raddr <= s_axi_arvalid ? s_axi_araddr : (
      s_axi_rvalid && s_axi_rready ? raddr + 4 : raddr);
    s_axi_arready <= s_axi_arvalid && !s_axi_arready;
    rburst <= s_axi_arvalid ? s_axi_arlen + 1 : (
      s_axi_rvalid && s_axi_rready ? rburst - 1 : rburst);
  end
end

// reading
always @(posedge s_axi_aclk) begin
  if (s_axi_aresetn == 0) begin
    s_axi_rvalid <= 0;
    s_axi_rresp <= 2'b0;
    delay <= 3;
  end
  else begin
    if (rburst && yes && !s_axi_rvalid) begin
      s_axi_rvalid <= 1;
      s_axi_rresp <= 0;
    end
    else if (s_axi_rvalid && s_axi_rready) begin
      $display("read at %d = %d", raddr, s_axi_rdata);
      s_axi_rvalid <= 0;
      delay <= 3;
    end
    else
      delay <= delay - 1;
  end
end

// read from memory
always @(posedge s_axi_aclk) begin
  s_axi_rdata <= mem[raddr>>2];
end

// write to memory
always @(posedge s_axi_aclk) begin
  if (yes2)
    mem[waddr>>2] <= s_axi_wdata;
end

// get write address
always @(posedge s_axi_aclk) begin
  if (s_axi_aresetn == 0) begin
    waddr <= 0;
    s_axi_wready <= 0;
    wburst <= 0;
  end
  else begin
    waddr <= s_axi_awvalid ? s_axi_awaddr : (
      s_axi_wready && s_axi_wvalid ? waddr + 4 : waddr);
    s_axi_awready <= s_axi_awvalid && !s_axi_awready;
    wburst <= s_axi_awvalid ? s_axi_awlen + 1 : (
      s_axi_wvalid && s_axi_wready ? wburst - 1 : wburst);
  end
end

// writing
always @(posedge s_axi_aclk) begin
  if (s_axi_aresetn == 0) begin
    s_axi_wready <= 0;
    s_axi_bresp <= 2'b0;
    wdelay <= 3;
  end
  else begin
    if (wburst && yes2 && !s_axi_wready) begin
      s_axi_wready <= 1;
      s_axi_bresp <= 2'b0;
    end
    else if (s_axi_wready && s_axi_wvalid) begin
      $display("write to %d = %d", waddr, s_axi_wdata);
      s_axi_wready <= 0;
      wdelay <= 3;
    end
    else
      wdelay <= wdelay - 1;
  end
end

// finish writing
always @(posedge s_axi_aclk)
if (s_axi_aresetn == 0) begin
  s_axi_bvalid <= 0;
end
else if (s_axi_wready && s_axi_wvalid && s_axi_wlast && !s_axi_bvalid) begin
  s_axi_bvalid <= 1;
end
else if (s_axi_bvalid && s_axi_bready) begin
  s_axi_bvalid <= 0;
end

endmodule
