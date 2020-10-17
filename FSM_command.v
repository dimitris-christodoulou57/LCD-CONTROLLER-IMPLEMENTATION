`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dimitris Christodoulou
// 
// Create Date:    01:01:17 12/19/2018 
// Design Name: 
// Module Name:    FSM_command 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module FSM_command(clk, reset, wait_next_command, start, wait_init_command, Enable_INIT, DATA_INIT, DATA_UPPER, DATA_LOW, RS, RW, LCD_RS, LCD_RW, SF_D, LCD_E);
	input clk, reset;
	input RS, RW, wait_next_command, wait_init_command, Enable_INIT, start;
	input [3:0] DATA_UPPER, DATA_LOW, DATA_INIT;
	output reg LCD_E, LCD_RS, LCD_RW; 
	output reg [11:8] SF_D;

	reg [8:0] Current_State;
	reg [8:0] Next_State;
	reg [10:0] counter;//measure cycle in order to change state
		
	//STATE ENCODING
	parameter STATE_INIT_DATA = 9'b000000001,
			  STATE_SETUP_UPPER = 9'b000000010,
			  STATE_DATA_UPPER  = 9'b000000100,
			  STATE_HOLD_UPPER  = 9'b000001000,
			  STATE_WAIT        = 9'b000010000,
			  STATE_SETUP_LOW   = 9'b000100000,
			  STATE_DATA_LOW    = 9'b001000000,
			  STATE_HOLD_LOW    = 9'b010000000,
			  STATE_WAIT_NEXT   = 9'b100000000;

	//State Registers - Sequential//
	always@(posedge clk or posedge reset)
	begin
		if(reset) 
		begin
			Current_State = STATE_INIT_DATA;
			counter = 11'd0;
		end
		else 
		begin
			if(wait_next_command || wait_init_command || start)//check amd change state when fsm command need to run.
			begin
				if(Current_State != Next_State)//when change state make counter zero else increase to know when change state
					counter = 11'd0;
				else
					counter = counter + 1;
				Current_State = Next_State;
			end
		end
	end
	
	always@(Current_State or counter or reset or wait_next_command or wait_init_command or start or DATA_INIT or Enable_INIT or RS or RW  or DATA_UPPER or DATA_LOW)
	begin
		if(reset)//reset initialize 
		begin
			Next_State = STATE_INIT_DATA;
			LCD_E = 1'b0;
			LCD_RS = 1'b0;
			LCD_RW = 1'b1;
			SF_D = 4'b0000;
		end
		else if (wait_next_command || wait_init_command || start)//check amd change state when fsm command need to run.
		begin
			Next_State = Current_State;
			LCD_E = 1'b0;
			LCD_RS = 1'b0;
			LCD_RW = 1'b1;
			SF_D = 4'b0000;
			case (Current_State)
				STATE_INIT_DATA://state init data run when run initial
				begin
					SF_D = DATA_INIT;//value from initial
					LCD_E = Enable_INIT;//data from initial
					if (wait_init_command)//when initial finish change state
						Next_State = STATE_SETUP_UPPER;
				end		
				STATE_SETUP_UPPER://stabilize data 2 cycle before enable = 1
				begin
					LCD_RS = RS;//value from configuration
					LCD_RW = RW;
					SF_D = DATA_UPPER;
					
					if(counter == 11'd1)//when counter take 1 value change state
						Next_State = STATE_DATA_UPPER;
					else
						Next_State = STATE_SETUP_UPPER;
				end
				STATE_DATA_UPPER://make enable = 1 for 12 cycle
				begin
					LCD_E = 1'b1;//LCD_E = 1 in this state. sent 4-bit upper
					LCD_RS = RS;
					LCD_RW = RW;
					SF_D = DATA_UPPER;
					
					if(counter == 11'd11)//when counter take 11 value change state
						Next_State = STATE_HOLD_UPPER;
					else
						Next_State = STATE_DATA_UPPER;
				end
				STATE_HOLD_UPPER://maitain data for 1 cycle 
				begin
					LCD_E = 1'b0;
					LCD_RS = RS;
					LCD_RW = RW;
					SF_D = DATA_UPPER;
					Next_State = STATE_WAIT;
				end
				STATE_WAIT://wait 940ns, then sent 4 lowwer bit
				begin
					LCD_RW = 1'b1;
					SF_D = DATA_LOW;
					if(counter == 11'd46)
						Next_State = STATE_SETUP_LOW;
					else
						Next_State = STATE_WAIT;
				end
				STATE_SETUP_LOW://stabilize data 2 cycle before enable = 1
				begin
					LCD_RS = RS;
					LCD_RW = RW;
					SF_D = DATA_LOW;
					
					if(counter == 11'd1)//when counter take 1 value change state
						Next_State = STATE_DATA_LOW;
					else
						Next_State = STATE_SETUP_LOW;
				end
				STATE_DATA_LOW://make enable = 1 for 12 cycle. sent 4-bit low 
				begin
					LCD_E = 1'b1;
					LCD_RS = RS;
					LCD_RW = RW;
					SF_D = DATA_LOW;
					
					if(counter == 11'd11)//when counter take 11 value change state
						Next_State = STATE_HOLD_LOW;
					else
						Next_State = STATE_DATA_LOW;
				end
				STATE_HOLD_LOW://maitain data for 1 cycle 
				begin
					LCD_E = 1'b0;
					LCD_RS = RS;
					LCD_RW = RW;
					SF_D = DATA_LOW;
					Next_State = STATE_WAIT_NEXT;
				end
				STATE_WAIT_NEXT://wait 940ns, then sent next command
				begin
					LCD_RW = 1'b1;
					LCD_RS = 1'b1;
					SF_D = DATA_UPPER;
					if(counter == 11'd1996)//return to first state
					begin
						Next_State = STATE_SETUP_UPPER;
					end
					else
						Next_State = STATE_WAIT_NEXT;
				end
			endcase
		end
		else
		begin
			Next_State = Current_State;
			LCD_E = 1'b0;
			LCD_RS = 1'b0;
			LCD_RW = 1'b1;
			SF_D = 4'b0000;
		end
	end

endmodule
