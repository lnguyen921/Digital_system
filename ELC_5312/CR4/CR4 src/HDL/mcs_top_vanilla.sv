module mcs_top_vanilla
#(parameter BRG_BASE = 32'hc000_0000)	
(
   input  logic clk,
   input  logic reset_n,
   // switches and LEDs
   input  logic [15:0] sw,
   output logic [15:0] led,
   // uart
   input  logic rx,
   output logic tx,
   
    // *** 7-segment display ***
   output logic [6:0] SEG,
   output logic       DP,
   output logic [7:0] AN,

   // *** SPI pins to ADXL362 ***
   output logic spi_sclk,
   output logic spi_mosi,
   input  logic spi_miso,
   output logic spi_ss_n
);

   // declaration
   logic clk_100M;
   logic reset_sys;
   // MCS IO bus
   logic io_addr_strobe;
   logic io_read_strobe;
   logic io_write_strobe;
   logic [3:0]  io_byte_enable;
   logic [31:0] io_address;
   logic [31:0] io_write_data;
   logic [31:0] io_read_data;
   logic        io_ready;
   // fpro bus 
   logic        fp_mmio_cs; 
   logic        fp_wr;      
   logic        fp_rd;     
   logic [20:0] fp_addr;       
   logic [31:0] fp_wr_data;    
   logic [31:0] fp_rd_data;    

   // body
   assign clk_100M  = clk;       // 100 MHz external clock
   assign reset_sys = !reset_n;
   
   //instantiate uBlaze MCS
   cpu cpu_unit (
    .Clk(clk_100M),
    .Reset(reset_sys),
    .IO_addr_strobe(io_addr_strobe),
    .IO_address(io_address),
    .IO_byte_enable(io_byte_enable),
    .IO_read_data(io_read_data),
    .IO_read_strobe(io_read_strobe),
    .IO_ready(io_ready),
    .IO_write_data(io_write_data),
    .IO_write_strobe(io_write_strobe)
   );
    
   // instantiate bridge
   chu_mcs_bridge #(.BRG_BASE(BRG_BASE)) bridge_unit (.*, .fp_video_cs());
    
   // instantiated i/o subsystem
   mmio_sys_vanilla #(.N_SW(16),.N_LED(16)) mmio_unit (
      .clk(clk),
      .reset(reset_sys),
      .mmio_cs(fp_mmio_cs),
      .mmio_wr(fp_wr),
      .mmio_rd(fp_rd),
      .mmio_addr(fp_addr), 
      .mmio_wr_data(fp_wr_data),
      .mmio_rd_data(fp_rd_data),
      .sw(sw),
      .led(led),
      .rx(rx),
      .tx(tx),
      
      // 7-segment
      .SEG(SEG),
      .DP(DP),
      .AN(AN),

      // hook SPI through to IO pins
      .spi_sclk(spi_sclk),
      .spi_mosi(spi_mosi),
      .spi_miso(spi_miso),
      .spi_ss_n(spi_ss_n)
  );   
endmodule    


