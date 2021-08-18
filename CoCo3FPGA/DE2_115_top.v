////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 4.0
// File Name:		DE2_115_top.v
//
// CoCo3 in an FPGA
//
// Revision: 4.0 
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
// The FDC co-processor copyrighted Daniel Wallner.
// SDRAM Controller copyrighted by XESS Corp.
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 4.0
//
// Copyright (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// The latest version of this file can be found at:
//      http://groups.yahoo.com/group/CoCo3FPGA
//
// File history :
//
//  1.0			Full Release
//  2.0			Partial Release
//  3.0			Full Release
//  3.0.0.1		Update to fix DoD interrupt issue
//	3.0.1.0		Update to fix 32/40 CoCO3 Text issue and add 2 Meg max memory
//	4.0.X.X		Full Release
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
//
//	DE2_115_top by Stan Hodge 8/15/21
////////////////////////////////////////////////////////////////////////////////

module DE2_115_top(
// Input Clocks
input				CLK50MHZ,

// Video

output	[7:0]		RED,
output	[7:0]		GREEN,
output	[7:0]		BLUE,

output				H_SYNC,
output				V_SYNC,
output				VGA_SYNC_N,
output				VGA_BLANK_N,
output				VGA_CLK,
//output				HBLANK,
//output				VBLANK,

// PS/2
input				ps2_clk,
input				ps2_data,

// RS-232
output				DE1TXD,
input				DE1RXD,
output				OPTTXD,
input				OPTRXD,

// I2C - Audio
output				I2C_SCL,
inout				I2C_DAT,

//Codec - Audio
output				AUD_XCK,
input				AUD_BCLK,
output	 			AUD_DACDAT,
input				AUD_DACLRCK,
input				AUD_ADCDAT,
input				AUD_ADCLRCK,

// CoCo Joystick
output				PADDLE_MCLK,
input	[3:0]		PADDLE_CLK,
input	[3:0]		P_SWITCH,

//inout				GPIO,
output	[6:0]		PROBE,

// De2-115 specifics

input	[9:0]		DE2_SWITCHES,
input	[3:0]		DE2_BUTTONS_N,

output	[6:0]		SEGMENT0_N,
output	[6:0]		SEGMENT1_N,
output	[6:0]		SEGMENT2_N,
output	[6:0]		SEGMENT3_N,
output	[6:0]		SEGMENT4_N,
output	[6:0]		SEGMENT5_N,
output	[6:0]		SEGMENT6_N,
output	[6:0]		SEGMENT7_N,

output	[8:0]		LEDG,
output	[17:0]		LEDR


);


POR CoCo3por(
	.CLK(CLK50MHZ),
	.POR(coco3_por)
	);


wire	coco3_por;
wire	COCO_RESET_N;
wire	EE_N;
wire	[31:0]	probe_wide;

assign COCO_RESET_N = DE2_BUTTONS_N[3] & ~coco3_por;

assign EE_N = DE2_BUTTONS_N[0];

assign LEDR[17:8] = 10'b0000000000;
assign LEDR[7:0] = probe_wide[15:8];
assign LEDG[8:0] = {1'b0, probe_wide[23:16]};

assign SEGMENT0_N =	{7'b0100011};					//o
assign SEGMENT1_N =	{7'b1000110};					//C
assign SEGMENT2_N =	{7'b0100011};					//o
assign SEGMENT3_N =	{7'b1000110};					//C

assign PROBE[6:0] = probe_wide[6:0];

Counter_Display DC(
	.clk(CLK50MHZ),
	.n_reset(COCO_RESET_N),
	.counter_item(!OPTRXD),
	.Digit4(SEGMENT7_N),
	.Digit3(SEGMENT6_N),
	.Digit2(SEGMENT5_N),
	.Digit1(SEGMENT4_N)
);



// connected externally to DE2_SWITCHES
//assign Switch[9:0] = 10'b0000010000; // This is ECB
//assign SWITCH[9:0] = 10'b0000010110; // This is EDB
//assign SWITCH[9:0] = 10'b0000000000; // This is Orch 80 in ROM

coco3fpga_dw COCO3(

	.CLK50MHZ(CLK50MHZ),
	.COCO_RESET_N(COCO_RESET_N),

	.RED(RED),
	.GREEN(GREEN),
	.BLUE(BLUE),

	.H_SYNC(H_SYNC),
	.V_SYNC(V_SYNC),
	.VGA_SYNC_N(VGA_SYNC_N),
	.VGA_BLANK_N(VGA_BLANK_N),
	.VGA_CLK(VGA_CLK),
//	.HBLANK(HBLANK),
//	.VBLANK(VBLANK),

// PS/2
	.ps2_clk(ps2_clk),
	.ps2_data(ps2_data),

// RS-232
	.DE1TXD(DE1TXD),
	.DE1RXD(DE1RXD),
	.OPTTXD(OPTTXD),
	.OPTRXD(OPTRXD),

// I2C - Audio
	.I2C_SCL(I2C_SCL),
	.I2C_DAT(I2C_DAT),

//Codec - Audio
	.AUD_XCK(AUD_XCK),
	.AUD_BCLK(AUD_BCLK),
	.AUD_DACDAT(AUD_DACDAT),
	.AUD_DACLRCK(AUD_DACLRCK),
	.AUD_ADCDAT(AUD_ADCDAT),
	.AUD_ADCLRCK(AUD_ADCLRCK),

// CoCo Joystick
	.PADDLE_MCLK(PADDLE_MCLK),
	.PADDLE_CLK(PADDLE_CLK),
	.P_SWITCH(P_SWITCH),

//	Config Static switches
	.SWITCH(DE2_SWITCHES),			

// roms, cartridges, etc
	.ioctl_data(8'b00000000),
	.ioctl_addr(16'b0000000000000000),
	.ioctl_download(1'b0),
	.ioctl_wr(DE2_SWITCHES[7]),
	.ioctl_index(DE2_SWITCHES[8]),


//	GPIO
//	.GPIO(GPIO),

	.EE_N(EE_N),
	.PROBE(probe_wide)

);

endmodule
