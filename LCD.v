`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:36:51 01/05/2019 
// Design Name: 
// Module Name:    LCD 
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
module LCD(clk, reset, LCD_RS, LCD_RW, SF_D, LCD_E);
input clk, reset;
output LCD_RS, LCD_RW, LCD_E;
output [11:8] SF_D;

wire [7:0] data;
wire [10:0] memory_addr;
wire [3:0] data_init;
wire [6:0] addr;
wire [3:0] data_low, data_high;
wire rs, rw, wait_next_command, wait_init_command, start, enable_init;
wire change_addr, change_memory_addr;
wire new_reset;

ANTI_BOUNCE ANTI_BOUNCE_INST(.clk(clk),
									.button_signal(reset),
									.button_state(new_reset));	

CONTROLLER CONTROLLER_INST(.clk(clk),
									.reset(new_reset),
									.change_addr(change_addr),
									.change_memory_addr(change_memory_addr),
									.start(start),
									.addr(addr),
									.memory_addr(memory_addr));

LCD_INITIAL LCD_INITIAL_INST(.clk(clk), 
									.reset(new_reset), 
									.start(start),
									.enable_init(enable_init),
									.wait_init_command(wait_init_command),
									.data(data_init));

Configuration Configuration_INST(.clk(clk),
											.reset(new_reset), 
											.start(start), 
											.DATA_LOW(data_low), 
											.DATA_HIGH(data_high), 
											.DATA(data), 
											.RS(rs), 
											.RW(rw), 
											.addr(addr), 
											.memory_addr(memory_addr), 
											.change_addr(change_addr),
											.change_memory_addr(change_memory_addr),
											.wait_next_command(wait_next_command));

FSM_command FSM_command_INST(.clk(clk), 
									  .reset(new_reset),
									  .wait_next_command(wait_next_command),
									  .start(start),
                             .wait_init_command(wait_init_command),
									  .Enable_INIT(enable_init),
									  .DATA_INIT(data_init),
									  .DATA_UPPER(data[7:4]), 
									  .DATA_LOW(data[3:0]), 
									  .RS(rs), 
									  .RW(rw), 
									  .LCD_RS(LCD_RS), 
									  .LCD_RW(LCD_RW), 
									  .SF_D(SF_D), 
									  .LCD_E(LCD_E));

memory_ram memory_ram_inst(.clk(clk),
									.reset(new_reset), 
									.memory_addr(memory_addr), 
									.data({data_high,data_low}));

endmodule
