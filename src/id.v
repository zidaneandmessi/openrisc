`include "defines.v"

module id(

	input wire					  rst,
	input wire[`InstAddrBus]	  pc_i,
	input wire[`InstBus]          inst_i,

  	input wire[`AluOpBus]		  ex_aluop_i,

	input wire					  ex_wreg_i,
	input wire[`RegBus]			  ex_wdata_i,
	input wire[`RegAddrBus]       ex_wd_i,
	
	input wire					  mem_wreg_i,
	input wire[`RegBus]			  mem_wdata_i,
	input wire[`RegAddrBus]       mem_wd_i,
	
	input wire[`RegBus]           reg1_data_i,
	input wire[`RegBus]           reg2_data_i,

	input wire                    inst_invalid_i,

	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	output reg[`AluOpBus]         aluop_o,
	output reg[`AluSelBus]        alusel_o,
	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           reg2_o,
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output wire[`RegBus]          inst_o,
	output reg[11:0]			  ls_addr_o,

	output reg                    next_inst_invalid_o,
	
	output reg                    branch_flag_o,
	output reg[`RegBus]           branch_target_address_o,       
	output reg[`RegBus]           link_addr_o,
	
	output wire                   stallreq	
);

	reg[6:0]		opcode;
	reg[6:0]		func7;
	reg[2:0]		func3;
	reg[1:0]		func2;
	reg[4:0]		rs1;
	reg[4:0]		rs2;
	reg[4:0]		rs3;
	reg[4:0]		rd;
	reg[19:0]		imm20;
	reg[11:0]		imm12;
	reg[6:0]		imm7;
	reg[4:0]		imm5;

	reg[`RegBus]	imm;
	reg instvalid;
	wire[`RegBus] pc_plus_8;
	wire[`RegBus] pc_plus_4;
	wire[`RegBus] imm_branch_signedext;  
	wire[`RegBus] imm_jal_signedext;  

	reg stallreq_for_reg1_loadrelate;
	reg stallreq_for_reg2_loadrelate;
	wire pre_inst_is_load;

	assign pc_plus_8 = pc_i + 8;
	assign pc_plus_4 = pc_i + 4;
	assign imm_branch_signedext = {{20{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8]}; 
	assign imm_jal_signedext = {{12{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21]};   
	assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
	assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
														(ex_aluop_i == `EXE_LBU_OP)||
														(ex_aluop_i == `EXE_LH_OP) ||
														(ex_aluop_i == `EXE_LHU_OP)||
														(ex_aluop_i == `EXE_LW_OP) ||
														(ex_aluop_i == `EXE_LWR_OP)||
														(ex_aluop_i == `EXE_LWL_OP)||
														(ex_aluop_i == `EXE_LL_OP) ||
														(ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

	assign inst_o = inst_i;

	task decode_rtype;
		input wreg_i;
		input reg1_read_i;
		input reg2_read_i;
		input [7:0] aluop_i;
		input [2:0] alusel_i;
		input instvalid_i;

		begin
			wreg_o <= wreg_i;		aluop_o <= aluop_i;
			wd_o = rd;
			alusel_o <= alusel_i;		reg1_read_o <= reg1_read_i;	reg2_read_o <= reg2_read_i;
			instvalid <= instvalid_i;
		end	
	endtask

	task decode_itype;
		input wreg_i;
		input reg1_read_i;
		input reg2_read_i;
		input [7:0] aluop_i;
		input [2:0] alusel_i;
		input instvalid_i;

		begin
	  		wreg_o <= wreg_i;		aluop_o <= aluop_i;
	  		wd_o <= rd;			
	  		alusel_o <= alusel_i; reg1_read_o <= reg1_read_i;	reg2_read_o <= reg2_read_i; 
			imm <= {{20{imm12[11]}}, imm12}; 	
			instvalid <= instvalid_i;	
		end	
	endtask		

	task decode_stype;
		input wreg_i;
		input reg1_read_i;
		input reg2_read_i;
		input [7:0] aluop_i;
		input [2:0] alusel_i;
		input instvalid_i;

		begin
			wreg_o <= wreg_i;		aluop_o <= aluop_i;
			wd_o = rd;
			alusel_o <= alusel_i;		reg1_read_o <= reg1_read_i;	reg2_read_o <= reg2_read_i;
			instvalid <= instvalid_i;	
		end
	endtask
    
	task decode_btype;
		input wreg_i;
		input reg1_read_i;
		input reg2_read_i;
		input [7:0] aluop_i;
		input [2:0] alusel_i;
		input instvalid_i;

		begin
			wreg_o <= wreg_i;		aluop_o <= aluop_i;
	  		alusel_o <= alusel_i; reg1_read_o <= reg1_read_i;	reg2_read_o <= reg2_read_i;
	  		instvalid <= instvalid_i;	
	  		case(aluop_i)
	  		`EXE_BEQ_OP: begin
		  		if(reg1_o == reg2_o) begin
			    	branch_target_address_o <= pc_i + (imm_branch_signedext << 1);
			    	branch_flag_o <= `Branch;
					next_inst_invalid_o <= `InstInvalid;
			    end
	  		end
	  		`EXE_BNE_OP: begin
		  		if(reg1_o != reg2_o) begin
			    	branch_target_address_o <= pc_i + (imm_branch_signedext << 1);
			    	branch_flag_o <= `Branch;
					next_inst_invalid_o <= `InstInvalid;
			    end
	  		end
	  		`EXE_BGE_OP: begin
		  		if($signed(reg1_o) >=  $signed(reg2_o)) begin
			    	branch_target_address_o <= pc_i + (imm_branch_signedext << 1);
			    	branch_flag_o <= `Branch;
					next_inst_invalid_o <= `InstInvalid;
			    end
	  		end
	  		`EXE_BLT_OP: begin
		  		if($signed(reg1_o) <  $signed(reg2_o)) begin
			    	branch_target_address_o <= pc_i + (imm_branch_signedext << 1);
			    	branch_flag_o <= `Branch;
					next_inst_invalid_o <= `InstInvalid;
			    end
	  		end
	  		`EXE_BGEU_OP: begin
		  		if(reg1_o >= reg2_o) begin
			    	branch_target_address_o <= pc_i + (imm_branch_signedext << 1);
			    	branch_flag_o <= `Branch;
					next_inst_invalid_o <= `InstInvalid;
			    end
	  		end
	  		`EXE_BLTU_OP: begin
		  		if(reg1_o < reg2_o) begin
			    	branch_target_address_o <= pc_i + (imm_branch_signedext << 1);
			    	branch_flag_o <= `Branch;
					next_inst_invalid_o <= `InstInvalid;
			    end
	  		end
	  		default:;
	  		endcase	
		end
	endtask


	task decode_utype;
		input wreg_i;
		input [7:0] aluop_i;
		input [2:0] alusel_i;
		input instvalid_i;

		begin
	  		wreg_o <= wreg_i;		aluop_o <= aluop_i;
	  		wd_o <= rd;			
	  		alusel_o <= alusel_i; reg1_read_o <= 0;	reg2_read_o <= 0; 
			imm <= {imm20, 12'h0}; 	
			instvalid <= instvalid_i;	
		end	
	endtask		

	always @ (*) begin	//所有输入信号，以及不受这个块控制的输出信号全部敏感
		opcode	= inst_i[6:0];
		func7 	= inst_i[31:25];
		func3	= inst_i[14:12];
		func2	= inst_i[26:25];
		rs1		= inst_i[19:15];
		rs2		= inst_i[24:20];
		rs3 	= inst_i[31:27];
		rd 		= inst_i[11:7];
		imm20	= inst_i[31:12];
		imm12	= inst_i[31:20];
		imm7	= inst_i[31:25];
		imm5	= inst_i[11:7];

		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;	
			link_addr_o <= `ZeroWord;
			ls_addr_o <= 12'h0;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_invalid_o <= `InstValid;		
	  end else if (inst_invalid_i == `InstInvalid) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= rs1;
			reg2_addr_o <= rs2;		
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			ls_addr_o <= 12'h0;
			branch_target_address_o <= `ZeroWord;	
			branch_flag_o <= `NotBranch;
			next_inst_invalid_o <= `InstValid;
	  end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= rd;
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= rs1;
			reg2_addr_o <= rs2;		
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			ls_addr_o <= 12'h0;
			branch_target_address_o <= `ZeroWord;	
			branch_flag_o <= `NotBranch;
			branch_flag_o <= `NotBranch;


		  case(opcode)
		  	`EXE_OP:	begin
		  		case(func3)
		  			3'b000:	begin
						case(func7)
						7'b0000000: 	decode_rtype(`WriteEnable, 1, 1, `EXE_ADD_OP, `EXE_RES_ARITHMETIC, `InstValid);
						7'b0100000: 	decode_rtype(`WriteEnable, 1, 1, `EXE_SUB_OP, `EXE_RES_ARITHMETIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_MUL_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b001: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SLL_OP, `EXE_RES_SHIFT, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_MULH_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b010: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SLT_OP, `EXE_RES_ARITHMETIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_MULHSU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b011: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SLTU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_MULHU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b100: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_XOR_OP, `EXE_RES_LOGIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_DIV_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b101: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SRL_OP, `EXE_RES_SHIFT, `InstValid);
						7'b0100000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SRA_OP, `EXE_RES_SHIFT, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_DIVU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end	
					3'b110: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_OR_OP, `EXE_RES_LOGIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_REM_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b111: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_AND_OP, `EXE_RES_LOGIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_REMU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					default:;
		  		endcase
		  	end

		  	`EXE_OP_IMM: begin
				case(func3)
				3'b000:			decode_itype(`WriteEnable, 1, 0, `EXE_ADDI_OP, `EXE_RES_ARITHMETIC, `InstValid);
				3'b001:			decode_itype(`WriteEnable, 1, 0, `EXE_SLL_OP, `EXE_RES_SHIFT, `InstValid);
				3'b010:			decode_itype(`WriteEnable, 1, 0, `EXE_SLT_OP, `EXE_RES_ARITHMETIC, `InstValid);
				3'b011:			decode_itype(`WriteEnable, 1, 0, `EXE_SLT_OP, `EXE_RES_ARITHMETIC, `InstValid);
				3'b100:			decode_itype(`WriteEnable, 1, 0, `EXE_XOR_OP, `EXE_RES_LOGIC, `InstValid);
				3'b101: begin
					case(func7)
					7'b0000000:		decode_itype(`WriteEnable, 1, 0, `EXE_SRL_OP, `EXE_RES_SHIFT, `InstValid);
					7'b0100000:		decode_itype(`WriteEnable, 1, 0, `EXE_SRA_OP, `EXE_RES_SHIFT, `InstValid);
					default:;
					endcase
				end
				3'b110:			decode_itype(`WriteEnable, 1, 0, `EXE_OR_OP, `EXE_RES_LOGIC, `InstValid);
				3'b111:			decode_itype(`WriteEnable, 1, 0, `EXE_AND_OP, `EXE_RES_LOGIC, `InstValid);
				default:;
				endcase
		  	end

		  	`EXE_OP_32:	begin
		  		case(func3)
		  			3'b000:	begin
						case(func7)
						7'b0000000: 	decode_rtype(`WriteEnable, 1, 1, `EXE_ADD_OP, `EXE_RES_ARITHMETIC, `InstValid);
						7'b0100000: 	decode_rtype(`WriteEnable, 1, 1, `EXE_SUB_OP, `EXE_RES_ARITHMETIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_MUL_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b001: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SLL_OP, `EXE_RES_SHIFT, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_MULH_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b010: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SLT_OP, `EXE_RES_ARITHMETIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_MULHSU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b011: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SLTU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_MULHU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b100: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_XOR_OP, `EXE_RES_LOGIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_DIV_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b101: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SRL_OP, `EXE_RES_SHIFT, `InstValid);
						7'b0100000:		decode_rtype(`WriteEnable, 1, 1, `EXE_SRA_OP, `EXE_RES_SHIFT, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_DIVU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end	
					3'b110: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_OR_OP, `EXE_RES_LOGIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_REM_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
					3'b111: begin
						case(func7)
						7'b0000000:		decode_rtype(`WriteEnable, 1, 1, `EXE_AND_OP, `EXE_RES_LOGIC, `InstValid);
						7'b0000001:		decode_rtype(`WriteEnable, 1, 1, `EXE_REMU_OP, `EXE_RES_ARITHMETIC, `InstValid);
						default:;
						endcase
					end
		  		endcase
		  	end

		  	`EXE_OP_IMM_32:	begin
				case(func3)
				3'b000:			decode_itype(`WriteEnable, 1, 0, `EXE_ADDI_OP, `EXE_RES_ARITHMETIC, `InstValid);
				3'b001:			decode_itype(`WriteEnable, 1, 0, `EXE_SLL_OP, `EXE_RES_SHIFT, `InstValid);
				3'b010:			decode_itype(`WriteEnable, 1, 0, `EXE_SLT_OP, `EXE_RES_ARITHMETIC, `InstValid);
				3'b011:			decode_itype(`WriteEnable, 1, 0, `EXE_SLT_OP, `EXE_RES_ARITHMETIC, `InstValid);
				3'b100:			decode_itype(`WriteEnable, 1, 0, `EXE_XOR_OP, `EXE_RES_LOGIC, `InstValid);
				3'b101: begin
					case(func7)
					7'b0000000:		decode_itype(`WriteEnable, 1, 0, `EXE_SRL_OP, `EXE_RES_SHIFT, `InstValid);
					7'b0100000:		decode_itype(`WriteEnable, 1, 0, `EXE_SRA_OP, `EXE_RES_SHIFT, `InstValid);
					default:;
					endcase
				end
				3'b110:			decode_itype(`WriteEnable, 1, 0, `EXE_OR_OP, `EXE_RES_LOGIC, `InstValid);
				3'b111:			decode_itype(`WriteEnable, 1, 0, `EXE_AND_OP, `EXE_RES_LOGIC, `InstValid);
				default:;
				endcase
		  	end

		  	`EXE_LOAD: begin
		  		case(func3)
		  		3'b000:			decode_itype(`WriteEnable, 1, 0, `EXE_LB_OP, `EXE_RES_LOAD_STORE, `InstValid);
		  		3'b001:			decode_itype(`WriteEnable, 1, 0, `EXE_LH_OP, `EXE_RES_LOAD_STORE, `InstValid);
		  		3'b010:			decode_itype(`WriteEnable, 1, 0, `EXE_LW_OP, `EXE_RES_LOAD_STORE, `InstValid);
		  		3'b100:			decode_itype(`WriteEnable, 1, 0, `EXE_LBU_OP, `EXE_RES_LOAD_STORE, `InstValid);
		  		3'b101:			decode_itype(`WriteEnable, 1, 0, `EXE_LHU_OP, `EXE_RES_LOAD_STORE, `InstValid);
		  		default:;
		  		endcase
		  		ls_addr_o <= imm12;
		  	end

		  	`EXE_STORE: begin
		  		case(func3)
		  		3'b000:			decode_stype(`WriteDisable, 1, 1, `EXE_SB_OP, `EXE_RES_LOAD_STORE, `InstValid);
		  		3'b001:			decode_stype(`WriteDisable, 1, 1, `EXE_SH_OP, `EXE_RES_LOAD_STORE, `InstValid);
		  		3'b010:			decode_stype(`WriteDisable, 1, 1, `EXE_SW_OP, `EXE_RES_LOAD_STORE, `InstValid);
		  		default:;
		  		endcase
		  		ls_addr_o <= {imm7, imm5};
		  	end

		  	`EXE_BRANCH: begin
		  		case(func3)
		  		3'b000:			decode_btype(`WriteDisable, 1, 1, `EXE_BEQ_OP, `EXE_RES_JUMP_BRANCH, `InstValid);
		  		3'b001:			decode_btype(`WriteDisable, 1, 1, `EXE_BNE_OP, `EXE_RES_JUMP_BRANCH, `InstValid);
		  		3'b100:			decode_btype(`WriteDisable, 1, 1, `EXE_BLT_OP, `EXE_RES_JUMP_BRANCH, `InstValid);
		  		3'b101:			decode_btype(`WriteDisable, 1, 1, `EXE_BGE_OP, `EXE_RES_JUMP_BRANCH, `InstValid);
		  		3'b110:			decode_btype(`WriteDisable, 1, 1, `EXE_BLTU_OP, `EXE_RES_JUMP_BRANCH, `InstValid);
		  		3'b111:			decode_btype(`WriteDisable, 1, 1, `EXE_BGEU_OP, `EXE_RES_JUMP_BRANCH, `InstValid);
		  		default:;
		  		endcase	
		  	end

		  	`EXE_JALR: begin
				wreg_o <= `WriteEnable;		aluop_o <= `EXE_JALR_OP;
				alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
				wd_o <= rd;
				link_addr_o <= pc_plus_4;
				branch_target_address_o <= reg1_o;
			    branch_flag_o <= `Branch;
			    instvalid <= `InstValid;	
				next_inst_invalid_o <= `InstInvalid;	
		  	end

		  	`EXE_JAL: begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_JAL_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  		wd_o <= rd;	
		  		link_addr_o <= pc_plus_4;
			    branch_target_address_o <= pc_i + (imm_jal_signedext << 1);
			    branch_flag_o <= `Branch;
			    instvalid <= `InstValid;	
				next_inst_invalid_o <= `InstInvalid;	
		  	end

		  	`EXE_LUI:		decode_utype(`WriteEnable, `EXE_OR_OP, `EXE_RES_LOGIC, `InstValid);

		  	`EXE_AUIPC:		decode_utype(`WriteEnable, `EXE_ADD_OP, `EXE_RES_ARITHMETIC, `InstValid);
														  	
		    default:;
		  endcase		  //case op
		end       //if
	end         //always
	

	always @ (*) begin
		stallreq_for_reg1_loadrelate <= `NoStop;	
		if(rst == `RstEnable || opcode == `EXE_LUI) begin
			reg1_o <= `ZeroWord;	
		end else if (opcode == `EXE_AUIPC) begin
			reg1_o <= pc_i;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  stallreq_for_reg1_loadrelate <= `Stop;							
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg1_addr_o) && rs1 != 5'b0) begin
			reg1_o <= ex_wdata_i; 
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i;	
	  	end else if(reg1_read_o == 1'b1) begin
			reg1_o <= reg1_data_i;	
	  	end else if(reg1_read_o == 1'b0) begin
	  		reg1_o <= imm;
	  	end else begin
	    	reg1_o <= `ZeroWord;
	  end
	end
	
	always @ (*) begin
		stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stallreq_for_reg2_loadrelate <= `Stop;			
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg2_addr_o) && rs2 != 5'b0) begin
			reg2_o <= ex_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;	
	  	end else if(reg2_read_o == 1'b1) begin
	  		reg2_o <= reg2_data_i;
	 	 end else if(reg2_read_o == 1'b0) begin
	 	 	reg2_o <= imm;
		  end else begin
	  		reg2_o <= `ZeroWord;
	  end
	end

endmodule