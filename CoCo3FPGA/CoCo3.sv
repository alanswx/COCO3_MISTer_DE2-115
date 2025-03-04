//============================================================================
//  CoCo3 port to MiSTer
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);


//`define SOUND_DBG
assign VGA_SL=0;
//assign CE_PIXEL=1;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign USER_OUT = '1;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign ADC_BUS  = 'Z;
//assign {SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 6'b111111;
//assign SDRAM_DQ = 'Z;


assign VGA_F1    = 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;


wire [1:0] ar = status[9:8];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;



`include "build_id.v"
localparam  CONF_STR = {
        "COCO3;;",
		  "O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
        "H0O2,Orientation,Vert,Horz;",
        "O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
		  "OA,Easter Egg,Off,On;",
		  "-;",
		  "OB,Turbo,Off,On;",
		  "OCD,MPI,Slot 1, Slot 2, Slot 3, Slot 4;",
			"OE,Video Odd Line Black,Off,On;",
"OF,SG4/6,SG4,SG6;",
"OG,Cart Interrupt Disabled,OFF,ON;",
        "-;",
        "R0,Reset;",
        "J1,Button;",
        "jn,A;",
        "V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys,clk_ram, clk_vid,clk_sys_2;

assign clk_sys=clk_vid;
//assign clk_sys = CLK_50M;
//assign clk_vid = CLK_50M;

wire pll_locked;

pll pll
(
        .refclk(CLK_50M),
        .rst(0),
        .outclk_0(clk_ram),
        .outclk_1(clk_vid),
		  .outclk_2(clk_sys_2),
        .locked(pll_locked)
);


///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_data;

wire [10:0] ps2_key;

wire [15:0] joy1 = joy1a | joy2a;
wire [15:0] joy2 = joy1a | joy2a;
wire [15:0] joy1a;
wire [15:0] joy2a;

wire [21:0] gamma_bus;

assign CLK_VIDEO = clk_sys;

hps_io #(.CONF_STR(CONF_STR),.PS2DIV(1000)) hps_io
(
//        .clk_sys(clk_sys),
		  .clk_sys(CLK_50M),
        .HPS_BUS(HPS_BUS),


        .buttons(buttons),
        .status(status),
        .status_menumask(direct_video),
        .forced_scandoubler(forced_scandoubler),
        .gamma_bus(gamma_bus),
        .direct_video(direct_video),

        .ioctl_download(ioctl_download),
        .ioctl_wr(ioctl_wr),
        .ioctl_addr(ioctl_addr),
        .ioctl_dout(ioctl_data),
        .ioctl_index(ioctl_index),

        .joystick_0(joy1a),
        .joystick_1(joy2a),
		  
        .ps2_key(ps2_key),


        .ps2_kbd_clk_out    ( ps2_kbd_clk    ),
        .ps2_kbd_data_out   ( ps2_kbd_data   )
);

wire ps2_kbd_clk;
wire ps2_kbd_data;


wire hblank, vblank;
wire hs, vs;

wire vga_clk;

video_mixer #(.GAMMA(1)) video_mixer
(
        .*,
	.freeze_sync(),

        .CLK_VIDEO(clk_vid),
        .ce_pix(vga_clk),

        .scandoubler(  1'b0),
        .hq2x(0),


        .R(r),
        //.R(8'b11111111),
        .G(g),
        .B(b),

        // Positive pulses.
        .HSync(hs),
        .VSync(vs),
        .HBlank(hblank),
        .VBlank(vblank)
);
//
//
assign AUDIO_L = {2'b0,/*6*/cocosound, 8'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;

wire [7:0] r;
wire [7:0] g;
wire [7:0] b;

wire easter_egg = ~status[10];
coco3fpga_dw coco3 (
.CLK50MHZ(CLK_50M),
.COCO_RESET_N(~reset),
//.COCO_RESET_N(1'b1),
.COCO_RESET_N_2(1'b1),

// SDRAM
/*
.SDRAM_ADDRESS(SDRAM_A),
.SDRAM_BANK(SDRAM_BA),
.SDRAM_DATA(SDRAM_DQ),
.SDRAM_LDQM(SDRAM_DQML),
.SDRAM_UDQM(SDRAM_DQMH),
.SDRAM_DQM(SDRAM_DQ),
.SDRAM_RAS_N(SDRAM_nRAS),
.SDRAM_CAS_N(SDRAM_nCAS),
.SDRAM_CKE(SDRAM_CKE),
.SDRAM_CLK(SDRAM_CLK),
.SDRAM_CS_N(SDRAM_nCS),
.SDRAM_RW_N(SDRAM_nWE),
*/


.RED(r),
.GREEN(g),
.BLUE(b),

.EE(easter_egg),

.H_SYNC(hs),
.V_SYNC(vs),
.HBLANK(hblank),
.VBLANK(vblank),
.VGA_CLK(vga_clk),
// PS/2
.ps2_clk(ps2_kbd_clk),
.ps2_data(ps2_kbd_data),
.ps2_key(ps2_key),
//.BUTTON_N(button_n)
.P_SWITCH(4'b1111),
.SWITCH(switch),
.SOUND_OUT(cocosound),

  .ioctl_addr(ioctl_addr),
  .ioctl_data(ioctl_data),
  .ioctl_download(ioctl_download),
  .ioctl_index(ioctl_index),
  .ioctl_wr(ioctl_wr)

);

wire [5:0] cocosound;


wire cpu_speed = status[11];
wire [1:0] mpi = status[13:12];		
wire video=status[14];
wire cartint=status[16];
wire sg4v6 = status[15];


wire [9:0] switch = { 10'b0000,sg4v6,cartint,video,mpi,cpu_speed} ;


wire reset = RESET | status[0] | buttons[1];
//wire reset = buttons[1];


endmodule
