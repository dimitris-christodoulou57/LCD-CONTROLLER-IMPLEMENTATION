`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dimitris Christodoulou
// 
// Create Date:    21:25:03 10/13/2018 
// Design Name: 
// Module Name:    ANTI-BOUNCE 
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
module ANTI_BOUNCE(clk, button_signal, button_state);
input clk;
input button_signal;
output reg button_state;//1 button is active(down)

//reg [1:0] button_counter;
//wire [1:0] button_counter_max;
reg [17:0] button_counter;
wire [17:0] button_counter_max;
reg sync_0;
reg sync_1;

always @(posedge clk)//synchronize clk and button
	sync_0 = button_signal;
	
always @(posedge clk)//synchronize clk and button
	sync_1 = sync_0;
	
//assign button_counter_max = 2'b11;//max when all bits of counter are 1
assign button_counter_max = 18'b111101000010010000;

always @(posedge clk or negedge sync_1)
begin
	if (sync_1 == 0)//release button
	begin
		button_counter = 0;//nothing going on
		button_state = 0;
	end
	else//push button
	begin
		button_counter = button_counter + 1'b1;//soething going on
		if (button_counter >= button_counter_max)
		begin
			button_state = 1;//if counter is greater than max button_state = 1 (active)
			button_counter = button_counter - 1;
		end
		else //button is unactive
		begin
			button_state = 0;
		end
	end
end

endmodule
