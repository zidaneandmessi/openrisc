`timescale 1ns / 1ps

`include "defines.v"

module cpu_core(
	input CLK,
	input RST,
	
	//To Memory Controller
	output reg[3:0] 	rw_flag,
	output reg[63:0]	addr,
	input wire[63:0]	read_data,
	output reg[63:0]	write_data,
	output reg[7:0]		write_mask,
	input wire[1:0]		busy,
	input wire[1:0]		done
);

	wire[`InstAddrBus] inst_addr;
	reg[`InstBus] inst;
	wire rom_ce;
	wire mem_we_i;
	wire[`RegBus] mem_addr_i;
	wire[`RegBus] mem_data_i;
	reg[`RegBus] mem_data_o;
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


	always @ (*) begin
		if (mem_ce_i) begin
			if (mem_we_i == 1) begin //write
				rw_flag[1:0] <= 2;
				addr[31:0] <= mem_addr_i;
				write_mask[3:0] <= mem_sel_i;
				mem_data_o <= read_data[31:0];
				write_data[31:0] <= mem_data_i;
			end
			else begin //read
				if (!done) begin
					rw_flag[1:0] <= 1;
					addr[31:0] <= mem_addr_i;
					write_mask[3:0] <= 4'h0;
					mem_data_o <= read_data[31:0];
				end
				else begin
					write_data[31:0] <= mem_data_o;
				end
			end
		end
		else begin
			rw_flag[1:0] <= 0;
			addr[31:0] <= 32'b0;
			write_mask[3:0] <= 4'b0;
			mem_data_o <= 32'b0;
			write_data[31:0] <= 32'b0;
		end
	end
	
	always @ (posedge CLK) begin
		if (rom_ce) begin
			if (!done) begin
				rw_flag[3:2] <= 1;
				addr[63:32] <= inst_addr;
				write_mask[7:4] <= 4'b0;
				write_data[63:32] <= 32'b0;
			end
			else begin
				inst <= read_data[63:32];
			end
		end
		else begin
			rw_flag[3:2] <= 0;
			addr[63:32] <= 32'b0;
			inst <= 32'b0;
			write_mask[7:4] <= 4'b0;
			write_data[63:32] <= 32'b0;
		end
		// rw_flag[3:2] <= 1;
		// addr[63:32] <= 4;
		// write_mask[7:4] <= 4'b0;
		// write_data[63:32] <= 32'b0;
	end



endmodule
