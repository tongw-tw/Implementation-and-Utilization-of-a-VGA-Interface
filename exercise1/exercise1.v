/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module exercise1 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[9:0] VGA_RED_O,              // VGA red
		output logic[9:0] VGA_GREEN_O,            // VGA green
		output logic[9:0] VGA_BLUE_O              // VGA blue
);

logic system_resetn;
logic Clock_50, Clock_25, Clock_25_locked;

// For VGA
logic [9:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

assign system_resetn = ~(SWITCH_I[17] || ~Clock_25_locked);

// PLL for clock generation
CLOCK_25_PLL CLOCK_25_PLL_inst (
	.areset(SWITCH_I[17]),
	.inclk0(CLOCK_50_I),
	.c0(Clock_50),
	.c1(Clock_25),
	.locked(Clock_25_locked)
);

// VGA unit
VGA_Controller VGA_unit(
	.Clock(Clock_25),
	.Resetn(system_resetn),

	.iRed(VGA_red),
	.iGreen(VGA_green),
	.iBlue(VGA_blue),
	.oCoord_X(pixel_X_pos),
	.oCoord_Y(pixel_Y_pos),
	
	//	VGA Side
	.oVGA_R(VGA_RED_O),
	.oVGA_G(VGA_GREEN_O),
	.oVGA_B(VGA_BLUE_O),
	.oVGA_H_SYNC(VGA_HSYNC_O),
	.oVGA_V_SYNC(VGA_VSYNC_O),
	.oVGA_SYNC(VGA_SYNC_O),
	.oVGA_BLANK(VGA_BLANK_O),
	.oVGA_CLOCK(VGA_CLOCK_O)
);

logic[1:0] mode;
logic vga_sync_buf;
logic [6:0] frame_counter;

always_ff @(posedge Clock_25 or negedge system_resetn) begin
	if(!system_resetn) begin
		vga_sync_buf <= 1'b0;
		mode <= 2'b00;
		frame_counter <= 7'd0;
	end else begin
		vga_sync_buf <= VGA_VSYNC_O;
		if (vga_sync_buf && !VGA_VSYNC_O) begin
			mode <= {SWITCH_I[1],SWITCH_I[0]};
			frame_counter <= frame_counter + 7'd1;
			if (({SWITCH_I[1],SWITCH_I[0]} == 2'b00) && (mode != 2'b00)) begin
				if (mode == 2'b01) frame_counter <= 7'd0;
				else frame_counter <= 7'd64;
			end
		end
	end
end

always_comb begin
	case (mode)
		2'b00: begin
					VGA_red = frame_counter[6] ? {10{~pixel_Y_pos[7]}} : {10{~pixel_X_pos[7]}};
					VGA_green = frame_counter[6] ? {10{~pixel_Y_pos[6]}} : {10{~pixel_X_pos[6]}};
					VGA_blue = frame_counter[6] ? {10{~pixel_Y_pos[5]}} : {10{~pixel_X_pos[5]}};
				 end
		2'b01: begin
					VGA_red = {10{~pixel_X_pos[7]}};
					VGA_green = {10{~pixel_X_pos[6]}};
					VGA_blue = {10{~pixel_X_pos[5]}};
				 end
		2'b10: begin
					VGA_red = {10{~pixel_Y_pos[7]}};
					VGA_green = {10{~pixel_Y_pos[6]}};
					VGA_blue = {10{~pixel_Y_pos[5]}};
				 end
		2'b11: begin
					VGA_red = {10{~pixel_X_pos[7] ^ ~pixel_Y_pos[7]}};
					VGA_green = {10{~pixel_X_pos[6] ^ ~pixel_Y_pos[6]}};
					VGA_blue = {10{~pixel_X_pos[5] ^ ~pixel_Y_pos[5]}};
				 end
	endcase
end

endmodule
