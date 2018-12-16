`include "defines.v"

module openrisc_min_sopc(

	input wire CLK,
	input wire RST
	
);

  //Á¬½ÓÖ¸Áî´æ´¢Æ÷
  wire[`InstAddrBus] inst_addr;
  wire[`InstBus] inst;
  wire rom_ce;
  wire mem_we_i;
  wire[`RegBus] mem_addr_i;
  wire[`RegBus] mem_data_i;
  wire[`RegBus] mem_data_o;
  wire[3:0] mem_sel_i;   
  wire mem_ce_i; 
 

 openrisc openrisc0(
		.clk(CLK),
		.rst(RST),
	
		.rom_addr_o(inst_addr),
		.rom_data_i(inst),
		.rom_ce_o(rom_ce),

		.ram_we_o(mem_we_i),
		.ram_addr_o(mem_addr_i),
		.ram_sel_o(mem_sel_i),
		.ram_data_o(mem_data_i),
		.ram_data_i(mem_data_o),
		.ram_ce_o(mem_ce_i)		
	
	);

	rom_ram rom_ram0(
		.rom_ce(rom_ce),
		.rom_addr(inst_addr),
		.rom_inst(inst),	

        .ram_clk(CLK),
        .ram_ce(mem_ce_i),
        .ram_we(mem_we_i),
        .ram_addr(mem_addr_i),
        .ram_sel(mem_sel_i),
        .ram_data_i(mem_data_i),
        .ram_data_o(mem_data_o) 
	);


endmodule