`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dimitris Christodoulou
// 
// Create Date:    15:08:55 12/19/2018 
// Design Name: 
// Module Name:    LCD_INITIAL 
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
module LCD_INITIAL(clk, reset, start, enable_init, wait_init_command, data);
	input clk, reset, start;
	output reg [3:0] data;
	output reg enable_init, wait_init_command;
	
	reg [5:0] Current_State, Next_State;
	reg [19:0]counter;//measure cycle in order to change state
	
	//STATE ENCODING
	parameter STATE_WAIT_15   = 6'b000001,
			  STATE_SF_D_3    = 6'b000010,
			  STATE_WAIT_4_1  = 6'b000100,
			  STATE_WAIT_100  = 6'b001000,
			  STATE_WAIT_40   = 6'b010000,
			  STATE_SF_D_2    = 6'b100000;
	
	//State Registers - Sequential//
	always@(posedge clk or posedge reset)
	begin
		if(reset) 
		begin
			Current_State = STATE_WAIT_15;
			counter = 20'd0;
		end
		else 
		begin
			counter = counter + 1;
			Current_State = Next_State;
			
		end
	end
	
	always@(reset or Current_State or start or counter)
	begin
		if(reset)//reset initialize 
		begin
			enable_init = 1'b0;
			wait_init_command = 1'b0;
			Next_State = Current_State;
			data = 4'b0;
		end
		else 
		begin
			if (start)//start = 1 so run initial, else run configuration
			begin
				enable_init = 1'b0;
				wait_init_command = 1'b0;
				Next_State = Current_State;
				data = 4'd0;
				case (Current_State)
					STATE_WAIT_15://wait 15ms before sent SF_D = 3
					begin
						if(counter == 20'd750000)//check counter to go to next state
						begin
							Next_State = STATE_SF_D_3;
							data = 4'd3; //assign the value number one cycle before-setup
						end
					end
					STATE_SF_D_3://sent data for 12 cycle
					begin
						enable_init = 1'b1;//enadle init = 1 to make LCD_E = 1
						data = 4'd3;
						case (counter)//check counter in order to know which state is next
							20'd750012: Next_State = STATE_WAIT_4_1;//wait 4.1ms
							20'd955024: Next_State = STATE_WAIT_100;//wait 100ìs
							20'd960036: Next_State = STATE_WAIT_40;//wait 100ìs
						endcase
						
					end
					STATE_WAIT_4_1://wait 4.1ms
					begin
						if (counter == 20'd955012)//check counter to go to next state
						begin
							Next_State = STATE_SF_D_3;
							data = 4'd3;//assign the value number one cycle before-setup
						end
					end
					STATE_WAIT_100://wait 100ìs
					begin
						if (counter == 20'd960024)//check counter to go to next state
						begin
							Next_State = STATE_SF_D_3;
							data = 4'd3;//assign the value number one cycle before-setup
						end
					end
					STATE_WAIT_40://wait 100ìs
					begin//check counter to go to next state
						if (counter == 20'd962036)
						begin
							Next_State = STATE_SF_D_2;
							data = 4'd2;//assign the value number one cycle before-setup
						end
						else if (counter == 20'd964048)
						begin
							Next_State = STATE_WAIT_15;
							wait_init_command = 1'b1;//initial finish. sent wait init command = 1 for 1 cycle to know other module that initial has finished
						end
					end
					STATE_SF_D_2://sent data for 12 cycle
					begin
						enable_init = 1'b1;//enadle init = 1 to make LCD_E = 1
						data = 4'd2;
						if (counter == 20'd962048)//check counter to go to next state
						begin
							Next_State = STATE_WAIT_40;
						end
					end
					default:
					begin
						data = 4'd0;
						enable_init = 1'b0;
					end
				endcase
			end
			else
			begin
				wait_init_command = 1'b0;
				Next_State = Current_State;
				data = 4'd0;
				enable_init = 1'b0;
			end
		end
	end	

endmodule