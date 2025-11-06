// mixed_address.v
module mixed_address;
  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 8;
  
  reg [3:0] clk_in;
  reg pclk, preset_n, psel, pwrite, penable;
  reg [ADDR_WIDTH-1:0] paddr;
  reg [DATA_WIDTH-1:0] pwdata;
  
  wire [DATA_WIDTH-1:0] prdata;
  wire pready, pslverr;
  wire TMR_OVF, TMR_UDF;
  
  timer_counter_8bit dut(
    .clk_in(clk_in),
    .pclk(pclk), 
    .preset_n(preset_n), 
    .psel(psel), 
    .pwrite(pwrite), 
    .penable(penable),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready), 
    .pslverr(pslverr),
    .TMR_OVF(TMR_OVF), 
    .TMR_UDF(TMR_UDF)
  );
  
  always #10 pclk = ~pclk;
  integer i;
  
  always @(*) begin
    if (pslverr) begin
      $display(,$time,,, "NULL_ADDRESS %h",paddr);
    end
  end
  
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
    pclk = 1; preset_n = 0; psel = 0; penable = 0; pwrite = 0; paddr = 8'h00;
    #20 preset_n = 1; psel = 1; penable = 0; pwrite = 0; paddr = $random;
    #40 penable = 1;
    #80; //Read reset value
    #40 pwrite = 1; pwdata = $random;
    #40 pwrite = 0;
    
    for (i=0; i<20; i=i+1) begin
      #40 pwrite = 1; paddr = $random; pwdata = $random;
      #40 pwrite = 0;
    end
    
    #100 $stop;
  end
  
endmodule
