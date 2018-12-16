`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/21 13:08:03
// Design Name: 
// Module Name: cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cpu(
	input EXCLK,
	input button,
	output Tx,
	input Rx,
	output reg[10:0] display_out, 
    input wire[15:0] button_in
	);
	
	// reg CLK = 0;
	// reg RST_Powerup;
	// reg reseted = 0;
	// always @(posedge EXCLK) begin
	// 	RST_Powerup <= 0;
	// 	if(!reseted) begin
	// 		RST_Powerup <= 1;
	// 		reseted <= 1;
	// 	end
	// 	CLK <= !CLK;
	// end
	
	reg RST;
	reg RST_delay;
	
	wire CLK;
	clk_wiz_0 clk(CLK, 1'b0, EXCLK);
	
	
    reg[6:0] num[0:9];

    initial begin
        num[0] <= 7'b1111110;
        num[1] <= 7'b0110000;
        num[2] <= 7'b1101101;
        num[3] <= 7'b1111001;
        num[4] <= 7'b0110011;
        num[5] <= 7'b1011011;
        num[6] <= 7'b1011111;
        num[7] <= 7'b1110000;
        num[8] <= 7'b1111111;
        num[9] <= 7'b1111011;
    end

    integer i, x0, x1, x2, x3;
    reg [19:0]count=0;
    reg [2:0] sel = 0;
    parameter T1MS=50000;

    initial begin
        x0 <= 0;
        x1 <= 0;
        x2 <= 0;
        x3 <= 0;
    end

    always @(posedge CLK) begin
        if (button_in[15] == 0) begin
            case (sel)
            0: display_out <= 11'b1110_1000001;
            1: display_out <= 11'b1101_0011000;
            2: display_out <= 11'b1011_0110001;
            3: display_out <= 11'b0111_1111111;
            default: display_out <= 11'b1111_1111111;
            endcase
        end else begin
            case (sel)
            0: display_out <= 11'b0111_1111111 - num[x0];
            1: display_out <= 11'b1011_1111111 - num[x1];
            2: display_out <= 11'b1101_1111111 - num[x2];
            3: display_out <= 11'b1110_1111111 - num[x3];
            default: display_out <= 11'b1111_1111111;
        endcase
        end
    end

    reg[12:0] ans;

    always @(button_in) begin
        for(i=0;i<13;i=i+1)
            ans[i]<=button_in[i];
        x0 <= ans /1000;
        x1 <= ans /100  % 10;
        x2 <= ans /10 % 10;
        x3 <= ans % 10;
    end

    always@ (posedge CLK) begin
        count <= count + 1;
        if(count == T1MS) begin
            count <= 0;
            sel <= sel + 1;
            if (sel == 4) sel <= 0;
        end
    end

	always @(posedge CLK) begin
		RST_delay <= 0;
		RST <= RST_delay;
	end
	
	wire 		UART_send_flag;
	wire [7:0]	UART_send_data;
	wire 		UART_recv_flag;
	wire [7:0]	UART_recv_data;
	wire		UART_sendable;
	wire		UART_receivable;
	
	uart_comm #(.BAUDRATE(5000000/*115200*/), .CLOCKRATE(66667000)) UART(
		CLK, RST,
		UART_send_flag, UART_send_data,
		UART_recv_flag, UART_recv_data,
		UART_sendable, UART_receivable,
		Tx, Rx);
	
	localparam CHANNEL_BIT = 1;
	localparam MESSAGE_BIT = 72;
	localparam CHANNEL = 1 << CHANNEL_BIT;
	
	wire 					COMM_read_flag[CHANNEL-1:0];
	wire [MESSAGE_BIT-1:0]	COMM_read_data[CHANNEL-1:0];
	wire [4:0]				COMM_read_length[CHANNEL-1:0];
	wire 					COMM_write_flag[CHANNEL-1:0];
	wire [MESSAGE_BIT-1:0]	COMM_write_data[CHANNEL-1:0];
	wire [4:0]				COMM_write_length[CHANNEL-1:0];
	wire					COMM_readable[CHANNEL-1:0];
	wire					COMM_writable[CHANNEL-1:0];
	
	multchan_comm #(.MESSAGE_BIT(MESSAGE_BIT), .CHANNEL_BIT(CHANNEL_BIT)) COMM(
		CLK, RST,
		UART_send_flag, UART_send_data,
		UART_recv_flag, UART_recv_data,
		UART_sendable, UART_receivable,
		{COMM_read_flag[1], COMM_read_flag[0]},
		{COMM_read_length[1], COMM_read_data[1], COMM_read_length[0], COMM_read_data[0]},
		{COMM_write_flag[1], COMM_write_flag[0]},
		{COMM_write_length[1], COMM_write_data[1], COMM_write_length[0], COMM_write_data[0]},
		{COMM_readable[1], COMM_readable[0]},
		{COMM_writable[1], COMM_writable[0]});
	
	wire [2*2-1:0]	MEM_rw_flag;
	wire [2*32-1:0]	MEM_addr;
	wire [2*32-1:0]	MEM_read_data;
	wire [2*32-1:0]	MEM_write_data;
	wire [2*4-1:0]	MEM_write_mask;
	wire [1:0]		MEM_busy;
	wire [1:0]		MEM_done;
	
	memory_controller MEM_CTRL(
		CLK, RST,
		COMM_write_flag[0], COMM_write_data[0], COMM_write_length[0],
		COMM_read_flag[0], COMM_read_data[0], COMM_read_length[0],
		COMM_writable[0], COMM_readable[0],
		MEM_rw_flag, MEM_addr,
		MEM_read_data, MEM_write_data, MEM_write_mask,
		MEM_busy, MEM_done);
	
	cpu_core CORE(
		CLK, RST,
		MEM_rw_flag, MEM_addr,
		MEM_read_data, MEM_write_data, MEM_write_mask,
		MEM_busy, MEM_done);
endmodule
