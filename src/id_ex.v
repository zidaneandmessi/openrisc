`include "defines.v"

module id_ex(

	input	wire				clk,
	input wire					rst,

	input wire[5:0]				stall,

	input wire[`AluOpBus]         id_aluop,
	input wire[`AluSelBus]        id_alusel,
	input wire[`RegBus]           id_reg1,
	input wire[`RegBus]           id_reg2,
	input wire[`RegAddrBus]       id_wd,
	input wire                    id_wreg,
	input wire[`RegBus]           id_link_address,
	input wire[`RegBus]           id_inst,		
	input wire[11:0]			  id_ls_offset,
	input wire					  next_inst_invalid_i,
	
	output reg[`AluOpBus]         ex_aluop,
	output reg[`AluSelBus]        ex_alusel,
	output reg[`RegBus]           ex_reg1,
	output reg[`RegBus]           ex_reg2,
	output reg[`RegAddrBus]       ex_wd,
	output reg                    ex_wreg,
	output reg[`RegBus]           ex_link_address,
	output reg[`RegBus]           ex_inst,	
	output reg[11:0]			  ex_ls_offset,

	output reg[11:0]			  inst_invalid_o
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;	
	    	ex_inst <= `ZeroWord;	
			ex_ls_offset <= 12'h0;
			inst_invalid_o <= `InstValid;
		end else if(stall[2] == `Stop && stall[3] == `NoStop) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;	
			ex_link_address <= `ZeroWord;
	    	ex_inst <= `ZeroWord;		
			ex_ls_offset <= 12'h0;	
			inst_invalid_o <= `InstValid;
		end else if(stall[2] == `NoStop) begin		
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;		
			ex_link_address <= id_link_address;
	    	ex_inst <= id_inst;				
			ex_ls_offset <= id_ls_offset;
			inst_invalid_o <= next_inst_invalid_i;
		end
	end
	
endmodule