
`timescale 1 ns / 1 ps

  module fastsad_v1_0 #
  (
  // Users to add parameters here
  parameter integer MY_BUF_ADDR_WIDTH = 11,
  
  // User parameters ends
  // Do not modify the parameters beyond this line


  // Parameters of Axi Slave Bus Interface S00_AXI
  parameter integer C_S00_AXI_DATA_WIDTH	= 32,
  parameter integer C_S00_AXI_ADDR_WIDTH	= 6,

  // Parameters of Axi Master Bus Interface M00_AXI
  parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
  parameter integer C_M00_AXI_BURST_LEN	= 16,
  parameter integer C_M00_AXI_ID_WIDTH	= 1,
  parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
  parameter integer C_M00_AXI_DATA_WIDTH	= 32,
  parameter integer C_M00_AXI_AWUSER_WIDTH	= 0,
  parameter integer C_M00_AXI_ARUSER_WIDTH	= 0,
  parameter integer C_M00_AXI_WUSER_WIDTH	= 0,
  parameter integer C_M00_AXI_RUSER_WIDTH	= 0,
  parameter integer C_M00_AXI_BUSER_WIDTH	= 0
  )
  (
  // Users to add ports here

  // User ports ends
  // Do not modify the ports beyond this line


  // Ports of Axi Slave Bus Interface S00_AXI
  input wire  s00_axi_aclk,
  input wire  s00_axi_aresetn,
  input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
  input wire [2 : 0] s00_axi_awprot,
  input wire  s00_axi_awvalid,
  output wire  s00_axi_awready,
  input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
  input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
  input wire  s00_axi_wvalid,
  output wire  s00_axi_wready,
  output wire [1 : 0] s00_axi_bresp,
  output wire  s00_axi_bvalid,
  input wire  s00_axi_bready,
  input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
  input wire [2 : 0] s00_axi_arprot,
  input wire  s00_axi_arvalid,
  output wire  s00_axi_arready,
  output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
  output wire [1 : 0] s00_axi_rresp,
  output wire  s00_axi_rvalid,
  input wire  s00_axi_rready,

  // Ports of Axi Master Bus Interface M00_AXI
  input wire  m00_axi_aclk,
  input wire  m00_axi_aresetn,
  output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_awid,
  output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
  output wire [7 : 0] m00_axi_awlen,
  output wire [2 : 0] m00_axi_awsize,
  output wire [1 : 0] m00_axi_awburst,
  output wire  m00_axi_awlock,
  output wire [3 : 0] m00_axi_awcache,
  output wire [2 : 0] m00_axi_awprot,
  output wire [3 : 0] m00_axi_awqos,
  output wire [C_M00_AXI_AWUSER_WIDTH-1 : 0] m00_axi_awuser,
  output wire  m00_axi_awvalid,
  input wire  m00_axi_awready,
  output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
  output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
  output wire  m00_axi_wlast,
  output wire [C_M00_AXI_WUSER_WIDTH-1 : 0] m00_axi_wuser,
  output wire  m00_axi_wvalid,
  input wire  m00_axi_wready,
  input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_bid,
  input wire [1 : 0] m00_axi_bresp,
  input wire [C_M00_AXI_BUSER_WIDTH-1 : 0] m00_axi_buser,
  input wire  m00_axi_bvalid,
  output wire  m00_axi_bready,
  output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_arid,
  output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
  output wire [7 : 0] m00_axi_arlen,
  output wire [2 : 0] m00_axi_arsize,
  output wire [1 : 0] m00_axi_arburst,
  output wire  m00_axi_arlock,
  output wire [3 : 0] m00_axi_arcache,
  output wire [2 : 0] m00_axi_arprot,
  output wire [3 : 0] m00_axi_arqos,
  output wire [C_M00_AXI_ARUSER_WIDTH-1 : 0] m00_axi_aruser,
  output wire  m00_axi_arvalid,
  input wire  m00_axi_arready,
  input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_rid,
  input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
  input wire [1 : 0] m00_axi_rresp,
  input wire  m00_axi_rlast,
  input wire [C_M00_AXI_RUSER_WIDTH-1 : 0] m00_axi_ruser,
  input wire  m00_axi_rvalid,
  output wire  m00_axi_rready
  );
// define wire name
wire  hw_active;
wire  [2:0] feature;
wire  [MY_BUF_ADDR_WIDTH-1:0]    len_copy;
wire  [C_S00_AXI_DATA_WIDTH-1:0] src_addr;
wire  [C_S00_AXI_DATA_WIDTH-1:0] dst_addr;
wire  [5:0]                      dst_row;
reg   hw_done;
reg   [C_S00_AXI_DATA_WIDTH-1:0] min_sad;
reg   [C_S00_AXI_DATA_WIDTH-1:0] min_sad_pos;

reg                              mem_active;
reg                              mem_to_write;
wire  [C_M00_AXI_DATA_WIDTH-1:0] mem_dst_addr = dst_addr;
reg   [31:0]                     mem_write_data;
wire  [MY_BUF_ADDR_WIDTH-1:0]    mem_write_col;
reg                              mem_write_enable;
wire  [C_M00_AXI_DATA_WIDTH-1:0] mem_src_addr = src_addr;
wire  [5:0]                      mem_dst_row = {1'b0, dst_row[4:0]};
reg   [MY_BUF_ADDR_WIDTH-1:0]    mem_read_col;
wire  [0:33*8-1]                 mem_col_data;
reg   [MY_BUF_ADDR_WIDTH-1:0]    mem_len_copy;

// for Compute_SAD
wire [31:0] sad_out;
wire        sad_valid;
wire [10:0]  sad_col_out;
// set face
reg          face_wr_en;
reg [2+10:0] face_wr_idx;
reg [7:0]    face_wr_data;
reg          face_select_en;
wire [1:0]   face_select;

reg pixel_ready;
reg [MY_BUF_ADDR_WIDTH-1:0] mem_col_data_addr;
// end of wire name

  
// Instantiation of Axi Bus Interface S00_AXI
  fastsad_v1_0_S00_AXI # (
  .MY_BUF_ADDR_WIDTH(MY_BUF_ADDR_WIDTH),
  .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
  ) fastsad_v1_0_S00_AXI_inst (
    .hw_active(hw_active),
    .feature(feature),
    // write to main memory
    .dst_addr(dst_addr),
    // read from main memory
    .src_addr(src_addr),
    .dst_row(dst_row),
    // both read and write
    .len_copy(len_copy),
    .hw_done(hw_done),
    .face_select(face_select),
    .min_sad(min_sad),
    .min_sad_pos(min_sad_pos),
  .S_AXI_ACLK(s00_axi_aclk),
  .S_AXI_ARESETN(s00_axi_aresetn),
  .S_AXI_AWADDR(s00_axi_awaddr),
  .S_AXI_AWPROT(s00_axi_awprot),
  .S_AXI_AWVALID(s00_axi_awvalid),
  .S_AXI_AWREADY(s00_axi_awready),
  .S_AXI_WDATA(s00_axi_wdata),
  .S_AXI_WSTRB(s00_axi_wstrb),
  .S_AXI_WVALID(s00_axi_wvalid),
  .S_AXI_WREADY(s00_axi_wready),
  .S_AXI_BRESP(s00_axi_bresp),
  .S_AXI_BVALID(s00_axi_bvalid),
  .S_AXI_BREADY(s00_axi_bready),
  .S_AXI_ARADDR(s00_axi_araddr),
  .S_AXI_ARPROT(s00_axi_arprot),
  .S_AXI_ARVALID(s00_axi_arvalid),
  .S_AXI_ARREADY(s00_axi_arready),
  .S_AXI_RDATA(s00_axi_rdata),
  .S_AXI_RRESP(s00_axi_rresp),
  .S_AXI_RVALID(s00_axi_rvalid),
  .S_AXI_RREADY(s00_axi_rready)
  );

// Instantiation of Axi Bus Interface M00_AXI
  fastsad_v1_0_M00_AXI # (
  .MY_BUF_ADDR_WIDTH(MY_BUF_ADDR_WIDTH),
  .C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
  .C_M_AXI_BURST_LEN(C_M00_AXI_BURST_LEN),
  .C_M_AXI_ID_WIDTH(C_M00_AXI_ID_WIDTH),
  .C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
  .C_M_AXI_AWUSER_WIDTH(C_M00_AXI_AWUSER_WIDTH),
  .C_M_AXI_ARUSER_WIDTH(C_M00_AXI_ARUSER_WIDTH),
  .C_M_AXI_WUSER_WIDTH(C_M00_AXI_WUSER_WIDTH),
  .C_M_AXI_RUSER_WIDTH(C_M00_AXI_RUSER_WIDTH),
  .C_M_AXI_BUSER_WIDTH(C_M00_AXI_BUSER_WIDTH)
  ) fastsad_v1_0_M00_AXI_inst (
    .hw_active(mem_active),
    .to_write(mem_to_write),
    // write to main memory
    .dst_addr(mem_dst_addr),
    .write_data(mem_write_data),
    .write_col(mem_write_col),
    .write_enable(mem_write_enable),
    // read from main memory
    .src_addr(mem_src_addr),
    .dst_row(mem_dst_row),
    .read_col(mem_read_col),
    .col_data(mem_col_data),
    // both read and write
    .len_copy(mem_len_copy),
    .hw_done(mem_done),
  .M_AXI_ACLK(m00_axi_aclk),
  .M_AXI_ARESETN(m00_axi_aresetn),
  .M_AXI_AWID(m00_axi_awid),
  .M_AXI_AWADDR(m00_axi_awaddr),
  .M_AXI_AWLEN(m00_axi_awlen),
  .M_AXI_AWSIZE(m00_axi_awsize),
  .M_AXI_AWBURST(m00_axi_awburst),
  .M_AXI_AWLOCK(m00_axi_awlock),
  .M_AXI_AWCACHE(m00_axi_awcache),
  .M_AXI_AWPROT(m00_axi_awprot),
  .M_AXI_AWQOS(m00_axi_awqos),
  .M_AXI_AWUSER(m00_axi_awuser),
  .M_AXI_AWVALID(m00_axi_awvalid),
  .M_AXI_AWREADY(m00_axi_awready),
  .M_AXI_WDATA(m00_axi_wdata),
  .M_AXI_WSTRB(m00_axi_wstrb),
  .M_AXI_WLAST(m00_axi_wlast),
  .M_AXI_WUSER(m00_axi_wuser),
  .M_AXI_WVALID(m00_axi_wvalid),
  .M_AXI_WREADY(m00_axi_wready),
  .M_AXI_BID(m00_axi_bid),
  .M_AXI_BRESP(m00_axi_bresp),
  .M_AXI_BUSER(m00_axi_buser),
  .M_AXI_BVALID(m00_axi_bvalid),
  .M_AXI_BREADY(m00_axi_bready),
  .M_AXI_ARID(m00_axi_arid),
  .M_AXI_ARADDR(m00_axi_araddr),
  .M_AXI_ARLEN(m00_axi_arlen),
  .M_AXI_ARSIZE(m00_axi_arsize),
  .M_AXI_ARBURST(m00_axi_arburst),
  .M_AXI_ARLOCK(m00_axi_arlock),
  .M_AXI_ARCACHE(m00_axi_arcache),
  .M_AXI_ARPROT(m00_axi_arprot),
  .M_AXI_ARQOS(m00_axi_arqos),
  .M_AXI_ARUSER(m00_axi_aruser),
  .M_AXI_ARVALID(m00_axi_arvalid),
  .M_AXI_ARREADY(m00_axi_arready),
  .M_AXI_RID(m00_axi_rid),
  .M_AXI_RDATA(m00_axi_rdata),
  .M_AXI_RRESP(m00_axi_rresp),
  .M_AXI_RLAST(m00_axi_rlast),
  .M_AXI_RUSER(m00_axi_ruser),
  .M_AXI_RVALID(m00_axi_rvalid),
  .M_AXI_RREADY(m00_axi_rready)
  );

  // Add user logic here
reg [3:0] state;
localparam Idle = 0;
localparam Init_read = 1;
localparam Reading = 2;
localparam Init_compute = 3;
localparam Compute = 4;
localparam Finish_compute = 5;
localparam Init_write_face = 6;
localparam Write_face = 7;
localparam Done = 8;
localparam Try_read = 9;
localparam Try_compute = 10;
localparam Done2 = 11;

pipe_sad #(
  .FACE_HEIGHT_BITS(5),
  .FACE_WIDTH_BITS(5),
  .GROUP_WIDTH_BITS(11),
  .FACE_COUNT_BITS(2)
) Compute_SAD (
  .clock(s00_axi_aclk),
  .reset(s00_axi_aresetn),
  .rotated_image(mem_col_data[0:255]),
  .row(dst_row[4:0]),
  .ready(pixel_ready),
  .col_in(mem_col_data_addr),
  .sad_out(sad_out),
  .valid(sad_valid),
  .col_out(sad_col_out),
// set face
  .face_wr_en(state == Write_face),
  .face_wr_row_idx({face_select, mem_col_data_addr[9:5]}),
  .face_wr_col_idx(mem_col_data_addr[4:0]),
  .face_wr_data(mem_col_data[0:7]),
  .face_select_en(state == Init_compute),
  .face_select(face_select)
);

always @ (posedge s00_axi_aclk) begin
  if (s00_axi_aresetn == 0 || state == Init_compute) begin
    min_sad <= -1;
    min_sad_pos <= 0;
  end
  else begin 
    if (sad_out <= min_sad && sad_valid && sad_col_out >= 31) begin
      min_sad <= sad_out;
      min_sad_pos <= sad_col_out;
    end
  end
end

always @(posedge s00_axi_aclk) begin
  mem_col_data_addr <= mem_read_col;
  pixel_ready <= state == Compute;
  mem_write_enable <= 0;
end

always @(posedge s00_axi_aclk) begin
  if (s00_axi_aresetn == 0) begin
    state <= Idle;
    mem_to_write <= 0;
    mem_active <= 0;
    hw_done <= 0;
  end
  else begin
    mem_active <= 0;
    hw_done <= 0;
    case (state)
      Idle: begin
        if (hw_active) state <= Try_read;
        else state <= Idle;
      end
      Try_read: begin
        if (feature[0] == 1) state <= Init_read;
        else state <= Try_compute;
      end
      Init_read: begin
        mem_to_write <= 0;
        mem_active <= 1;
        mem_len_copy <= len_copy;
        state <= Reading;
      end
      Reading: begin
        if (mem_done) state <= Try_compute;
        else state <= Reading;
      end
      Try_compute: begin
        if (feature[1] == 1) state <= Init_compute;
        else state <= Init_write_face;
      end
      Init_compute: begin
        state <= Compute;
        mem_read_col <= 0;
      end
      Compute: begin
        mem_read_col <= mem_read_col + 1;
        if (mem_read_col == len_copy-1) state <= Finish_compute;
        else state <= Compute;
      end
      Finish_compute: begin
        if (sad_col_out == len_copy-1 && sad_valid) state <= Done;
        else state <= Finish_compute;
      end
      Init_write_face: begin
        state <= Write_face;
        mem_read_col <= 0;
      end
      Write_face: begin
        mem_read_col <= mem_read_col + 1;
        if (mem_col_data_addr == len_copy-1) state <= Done;
        else state <= Write_face;
      end
      Done: begin
        hw_done <= 1;
        state <= Done2;
      end
      Done2: state <= Idle;
    endcase
  end
end

  // User logic ends

  endmodule
