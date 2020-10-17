`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dimitris Christodoulou
// 
// Create Date:    03:53:56 01/03/2019 
// Design Name: 
// Module Name:    Configuration 
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
module Configuration(clk, reset, start, DATA_LOW, DATA_HIGH, DATA, RS, RW, addr, memory_addr, change_addr, change_memory_addr, wait_next_command);
	input clk, reset, start;
	input [6:0] addr;
	input [10:0] memory_addr;
	input [3:0] DATA_HIGH, DATA_LOW;
	output reg [7:0] DATA;
	output reg RS, RW, wait_next_command, change_addr, change_memory_addr;
	
	reg [7:0] Current_State;
	reg [7:0] Next_State;
	reg [29:0] counter;//measure cycle in order to change state
	
	//STATE ENCODING
	parameter FUNCTION_SET    = 8'b00000001,
			  ENTRY_MODE_SET  = 8'b00000010,
			  DISPLAY         = 8'b00000100,
			  CLEAR_DISPLAY   = 8'b00001000,
			  WAIT_DATA       = 8'b00010000,
			  SET_DDRAM       = 8'b00100000,
			  DATA_STAGE      = 8'b01000000,
			  WAIT            = 8'b10000000;
			  
			  
	//State Registers - Sequential//
	always@(posedge clk or posedge reset)
	begin
		if(reset) 
		begin
			Current_State = FUNCTION_SET;
			counter = 30'd0;
		end
		else if(start == 1'b0)
		begin
			if(Current_State != Next_State)//when change state make counter zero else increase to know when change state
				counter = 30'd0;
			else
				counter = counter + 1;
			Current_State = Next_State;
		end
	end
	
	always@(Current_State or counter or reset or DATA_LOW or DATA_HIGH or start or addr or memory_addr)
	begin
		if(reset)//reset initialize 
		begin
			RS = 1'b0;
			RW = 1'b1;
			wait_next_command = 1'b0;
			change_addr= 1'b0;
			change_memory_addr = 1'b0;
			Next_State = FUNCTION_SET;
			DATA = 8'h00;
		end
		else
		begin
			if (start == 1'b0)//start = 0 so run configuration, else run initial
			begin
				wait_next_command = 1'b0;
				change_addr= 1'b0;
				change_memory_addr = 1'b0;
				Next_State = Current_State;
				case(Current_State)
					FUNCTION_SET:
					begin
						RS = 1'b0;//sent data to fsm_coomand
						RW = 1'b0;
						DATA[3:0] = 4'h8;
						DATA[7:4] = 4'h2;
						wait_next_command = 1'b1;//do 1 to run fsm_command
						if (counter == 30'd2073)//when counter take 2073(sent this command complete) value change state
							Next_State = ENTRY_MODE_SET;
					end
					ENTRY_MODE_SET:
					begin
						RS = 1'b0;//sent data to fsm_coomand
						RW = 1'b0;
						DATA[3:0] = 4'h6;
						DATA[7:4] = 4'h0;
						wait_next_command = 1'b1;//do 1 to run fsm_command
						if (counter == 30'd2073)//when counter take 2073(sent this command complete) value change state
							Next_State = DISPLAY;
					end
					DISPLAY:
					begin
						RS = 1'b0;//sent data to fsm_coomand
						RW = 1'b0;
						DATA[3:0] = 4'hC;
						DATA[7:4] = 4'h0;
						wait_next_command = 1'b1;//do 1 to run fsm_command
						if (counter == 30'd2073)//when counter take 2073(sent this command complete) value change state
							Next_State = CLEAR_DISPLAY;
					end
					CLEAR_DISPLAY:
					begin
						RS = 1'b0;//sent data to fsm_coomand
						RW = 1'b0;
						DATA[3:0] = 4'h1;
						DATA[7:4] = 4'h0;
						wait_next_command = 1'b1;//do 1 to run fsm_command
						if (counter == 30'd2073)//when counter take 2073(sent this command complete) value change state
							Next_State = WAIT_DATA;
					end
					WAIT_DATA://wait 82000cycle before sent message
					begin
						RW = 1'b1;
						RS = 1'b0;
						DATA = 8'h00;
						if (counter == 30'd82000)
						begin
							Next_State = SET_DDRAM;
						end
					end
					SET_DDRAM:
					begin
						RS = 1'b0;//sent data to fsm_coomand
						RW = 1'b0;
						DATA[6:0] = addr;//screen address from controller
						DATA[7] = 1'b1;
						
						wait_next_command = 1'b1;//do 1 to run fsm_command
						if (counter == 30'd2073)//when counter take 2073(sent this command complete) value change state
						begin
							change_addr= 1'b1;//do 1 in order to increase screen address (configuration)
							Next_State = DATA_STAGE;
						end
					end
					DATA_STAGE:
					begin
						RS = 1'b1;//sent data to fsm_coomand
						RW = 1'b0;
						DATA[3:0] = DATA_LOW;
						DATA[7:4] = DATA_HIGH;
						wait_next_command = 1'b1;//do 1 to run fsm_command
						//memory_addr = 31 when complete first message and memory_addr = 63 when complete second messege
						if (counter == 30'd2073 && (memory_addr == 11'd31 || memory_addr == 11'd63))//when display of messege complete go to wait state 
						begin
							change_memory_addr = 1'b1;//do 1 in order to increase memory address (configuration) 
							Next_State = WAIT;
						end
						else if(counter == 30'd2073)
						begin
							change_memory_addr = 1'b1;//do 1 in order to increase memory address(configuration) 
							Next_State = SET_DDRAM;
						end
					end
					WAIT:
					begin
						RW = 1'b1;//sent data to fsm_coomand
						RS = 1'b0;
						DATA = 8'h00;
						if (counter == 30'd50000000)//when counter take 50000000 return to start to display next message
						begin
							Next_State = FUNCTION_SET;
						end
					end
					default:
					begin
						RW = 1'b1;
						RS = 1'b0;
						DATA = 8'h00;
					end
				endcase
			end
			else
			begin
				RW = 1'b1;
				RS = 1'b0;
				change_addr= 1'b0;
				change_memory_addr = 1'b0;
				wait_next_command = 1'b0;
				Next_State = FUNCTION_SET;
				DATA = 8'h00;
			end
		end
	end

endmodule