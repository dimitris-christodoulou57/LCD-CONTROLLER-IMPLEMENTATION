`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dimitris Christodoulou
// 
// Create Date:    14:11:33 01/09/2019 
// Design Name: 
// Module Name:    CONTROLLER 
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
module CONTROLLER(clk, reset, change_addr, change_memory_addr, start, addr, memory_addr);
	input clk, reset, change_addr, change_memory_addr;
	output reg start;
	output reg [6:0] addr;
	output reg [10:0] memory_addr;
	
	reg [19:0] counter;

	always@(posedge clk or posedge reset)//control which fsm run
	begin
		if (reset)
		begin
			counter = 20'd0;
			start = 1'b1;
		end
		else
		begin
			if(counter <= 20'd964047)//if counter <= 964047, initial fsm run so start = 1
			begin
				counter = counter + 1;
				start = 1'b1;
			end
			else//else (initial fsm finish) start = 0 in order to run configuration run
				start = 1'b0;
		end
	end
	
	always@(posedge clk or posedge reset)//control screen address and memory address
	begin
		if(reset)
		begin
			addr = 7'd0;
			memory_addr = 11'd0;
		end
		else
		begin
			if(change_addr)//if change addr = 1, the state finish so go to next screen address
			begin
				if(addr == 7'd15)//if addr = 15, addr =64 in order to change line
					addr = 7'd64;
				else if (addr == 7'd79)//if addr = 79, addr = 0 in order to return to start
					addr = 7'd0;
				else
					addr = addr + 1;//go to next addr
			end
						
			if(change_memory_addr)//if change addr = 1, the state finish so go to next memory address
			begin
				if(memory_addr ==11'd63)//when memory addr = 63 return to start. 63 = 32 messege character + 32 refresh character.
					memory_addr = 11'd0;
				else
					memory_addr = memory_addr + 1;	
			end
		end
	end

endmodule
