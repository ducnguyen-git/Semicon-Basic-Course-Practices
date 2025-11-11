// countup_pause_countup_pclk2.v
module countup_pause_countup_pclk2;
  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 3;
  localparam COUNT_PAUSE = 10;
  
  reg [3:0] clk_in;
  reg pclk, preset_n;
  // Timer 1 for Thread 1
  reg psel_1, pwrite_1, penable_1;
  reg [ADDR_WIDTH-1:0] paddr_1;
  reg [DATA_WIDTH-1:0] pwdata_1;
  
  wire [DATA_WIDTH-1:0] prdata_1;
  wire pready_1, pslverr_1;
  wire TMR_OVF_1, TMR_UDF_1;
  
  // Timer 2 for Thread 2
  reg psel_2, pwrite_2, penable_2;
  reg [ADDR_WIDTH-1:0] paddr_2;
  reg [DATA_WIDTH-1:0] pwdata_2;
  
  wire [DATA_WIDTH-1:0] prdata_2;
  wire pready_2, pslverr_2;
  wire TMR_OVF_2, TMR_UDF_2;
  
  always #10 pclk = ~pclk;
  
  // Prescaler Initialization
  prescaler pres_dut(
    .clk_in(pclk), 
    .reset_n(preset_n), 
    .clk_0(clk_in[0]), 
    .clk_1(clk_in[1]), 
    .clk_2(clk_in[2]), 
    .clk_3(clk_in[3])
	);
  
  timer_counter_8bit timer_1(
    .clk_in(clk_in),
    .pclk(pclk), 
    .preset_n(preset_n), 
    .psel(psel_1), 
    .pwrite(pwrite_1), 
    .penable(penable_1),
    .paddr(paddr_1),
    .pwdata(pwdata_1),
    .prdata(prdata_1),
    .pready(pready_1), 
    .pslverr(pslverr_1),
    .TMR_OVF(TMR_OVF_1), 
    .TMR_UDF(TMR_UDF_1)
  );
  
  timer_counter_8bit timer_2(
    .clk_in(clk_in),
    .pclk(pclk), 
    .preset_n(preset_n), 
    .psel(psel_2), 
    .pwrite(pwrite_2), 
    .penable(penable_2),
    .paddr(paddr_2),
    .pwdata(pwdata_2),
    .prdata(prdata_2),
    .pready(pready_2), 
    .pslverr(pslverr_2),
    .TMR_OVF(TMR_OVF_2), 
    .TMR_UDF(TMR_UDF_2)
  );
  
  always @(TMR_UDF_1 or TMR_UDF_2) begin
    if (TMR_UDF_1 || TMR_UDF_2) begin
      $display(,$time,,, "faulty");
    end else begin
      $display(,$time,,, "pass");
    end
  end
  
  integer a,b;
  
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
    pclk = 1; preset_n = 0; 
    psel_1 = 0; penable_1 = 0; pwrite_1 = 0; paddr_1 = 3'b000; pwdata_1 = 8'h00;
    psel_2 = 0; penable_2 = 0; pwrite_2 = 0; paddr_2 = 3'b000; pwdata_2 = 8'h00;
    #20 preset_n = 1;
    fork
      // Thread 1
      begin
        #40 psel_1 = 1; penable_1 = 0; pwrite_1 = 0;
      	#40 penable_1 = 1; 
      	// Write TDR
        #80 pwrite_1 = 1; paddr_1 = 3'b010; pwdata_1 = {$random()} % 255; // Random 0-255
      	// Write TCR
      	#120 pwrite_1 = 1; paddr_1 = 3'b011; pwdata_1 = 8'b1000_0000; // Load, Count Up and choose clock T*2
        #210 pwdata_1 = 8'b0001_0000; // Enable
        // Pause
        #3000 pwdata_1 = 8'b0000_0000; // Deassert enable signal
        for (a=0; a < COUNT_PAUSE; a=a+1) begin
          @(posedge clk_in[0]);
        end
        #210 pwdata_1 = 8'b0001_0000; // Enable
       	#9000 paddr_1 = 3'b011; pwdata_1 = 8'b0000_0000; // Deassert enable signal
      end
    
    join_none
      // Thread 2
      begin
        #40 psel_2 = 1; penable_2 = 0; pwrite_2 = 0;
      	#40 penable_2 = 1; 
      	// Write TDR
        #80 pwrite_2 = 1; paddr_2 = 3'b010; pwdata_2 = {$random()} % 255; // Random 0-255
      	// Write TCR
      	#120 pwrite_2 = 1; paddr_2 = 3'b011; pwdata_2 = 8'b1000_0000; // Load, Count Up and choose clock T*2
        #210 pwdata_2 = 8'b0001_0000; // Enable
        // Pause
        #3000 pwdata_2 = 8'b0000_0000; // Deassert enable signal
        for (b=0; b < COUNT_PAUSE; b=b+1) begin
          @(posedge clk_in[0]);
        end
        #210 pwdata_2 = 8'b0001_0000; // Enable
        
       	#6000 paddr_2 = 3'b011; pwdata_2 = 8'b0000_0000; // Deassert enable signal
      end
    
    #9000 $stop;
  end
  
endmodule
