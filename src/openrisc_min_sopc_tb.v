`include "defines.v"
`timescale 1ns/1ps

module openrisc_min_sopc_tb();

  reg     CLK;
  reg     RST;
  
       
  initial begin
    CLK = 1'b0;
    forever #10 CLK = ~CLK;
  end
      
  initial begin
    RST = `RstEnable;
    #195 RST= `RstDisable;
    #10000 $stop;
  end
       
  openrisc_min_sopc openrisc_min_sopc0(
		.CLK(CLK),
		.RST(RST)	
	);

endmodule