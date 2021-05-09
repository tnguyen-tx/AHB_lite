// --=========================================================================--
// This confidential and proprietary software may be used only as
// authorised by a licensing agreement from ARM Limited
//   (C) COPYRIGHT 2000 ARM Limited
//       ALL RIGHTS RESERVED
// The entire notice above must be reproduced on all authorised
// copies and copies may only be made to the extent permitted
// by a licensing agreement from ARM Limited.
//
// -----------------------------------------------------------------------------
// Version and Release Control Information:
//
// File Name              : $RCSfile: $
// File Revision          : $Revision: $
//
// Release Information    : $State: $
//
// -----------------------------------------------------------------------------
// Purpose :
//           Example VHDL for Integrator Logic modules
//
// --=========================================================================--

`timescale 1ns/1ps

// library lmc;
// -----------------------------------------------------------------------------

module AHBAHBTop (
// Inputs
                  // AHB interface
                  HCLK,
                  HRESETn,
                  HTRANS,
                  HWRITE,
                  HSIZE,
                  nPBUTT,
                  SW,
                  HDRID,
                  HADDR,
		  SRDATA,
		  HWDATA,
//                  SDATA, //marked by nelson
// Outputs
		  HREADYout,
		  HRDATA,
                  HRESP,
                 // HBUSREQ,
                  HLOCK,
                  // APB I/O (SLAVE 1)
                  nLMINT,
                  LED,
                  CTRLCLK1,
                  CTRLCLK2,
                  // ZBT RAM (SLAVE 2)
                  SCLK,
                  SnWBYTE,
                  SnOE,
                  SnCE,
                  SADVnLD,
                  SnWR,
                  SnCKE,
                  SMODE,
		  SWDATA,	//added by nelson
                  SADDR,
                 );

// Inputs

// AHB interface
input            HCLK;      // system bus clock
input            HRESETn;   // reset input (active low)
input      [1:0] HTRANS;    // AHB transfer type CONT [1:0]
input            HWRITE;    // AHB hwrite CONT 11
input      [1:0] HSIZE;     // AHB hsize CONT [3:2]
input            nPBUTT;    // push button used as interrupt source
input      [7:0] SW;        // switches
input      [3:0] HDRID;     // LM ID
input     [31:0] HADDR;     // AHB address bus
input	  [31:0] SRDATA;    // SRAM read data bus	//added by nelson
input	  [31:0] HWDATA;    // AHB Write data bus	//added by nelson

// Inouts
//inout            HREADY;    // AHB ready CONT 12
//inout     [31:0] HDATA;     // AHB data bus (bi directional)
//inout     [31:0] SDATA;     // ZBT data bus // marked by nelson

// Outputs
output		 HREADYout;
output	  [31:0] HRDATA;   // AHB read data bus	//added by nelson
output     [1:0] HRESP;    // AHB response CONT [14:13]
//output           HBUSREQ;  // AHB request
output           HLOCK;    // AHB lock
// APB I/O (SLAVE 1)
output           nLMINT;   // LM peripheral interrupt request
output     [8:0] LED;      // LED control
output    [18:0] CTRLCLK1;  // sets frequency of CLK1
output    [18:0] CTRLCLK2;  // sets frequency of CLK2
// ZBT RAM (SLAVE 2)
output           SCLK;      // ZBT CLK
output     [3:0] SnWBYTE;   // ZBT byte write control signals
output           SnOE;      // ZBT output enable select
output           SnCE;      // ZBT chip select
output           SADVnLD;   // ZBT Mode pin
output           SnWR;      // ZBT advance signal
output           SnCKE;     // ZBT Clock enable signal
output           SMODE;     // ZBT mode signal
output	  [31:0] SWDATA;    // SRAM write data bus //added by nelson
output    [19:2] SADDR;     // ZBT address bus


// Inputs

// AHB interface
wire             HCLK;      // system bus clock
wire             TCK;       // test clock
wire             HRESETn;   // reset input (active low)
wire       [1:0] HTRANS;    // AHB transfer type CONT [1:0]
wire             HWRITE;    // AHB hwrite CONT 11
wire       [1:0] HSIZE;     // AHB hsize CONT [3:2]
wire             nPBUTT;    // push button used as interrupt source
wire       [7:0] SW;        // switches
wire       [3:0] HDRID;     // LM ID
wire             TDI;       // test data in
wire      [31:0] HADDR;     // AHB address bus

// Inouts
wire             HREADY;    // AHB ready CONT 12
wire      [31:0] HWDATA;    // AHB data bus 
//wire      [31:0] SDATA;     // ZBT data bus //marked by nelson

// Outputs
wire       [1:0] HRESP;    // AHB response CONT [14:13]
wire             HBUSREQ;   // AHB request
wire             HLOCK;     // AHB lock
wire             RTCK;      // return test clock (Multi-ICE feature)
// APB I/O (SLAVE 1)
wire             nLMINT;    // LM peripheral interrupt request
wire       [8:0] LED;       // LED control
wire      [18:0] CTRLCLK1;  // sets frequency of CLK1
wire      [18:0] CTRLCLK2;  // sets frequency of CLK2
// ZBT RAM (SLAVE 2)
wire             SCLK;      // ZBT CLK
wire       [3:0] SnWBYTE;   // ZBT byte write control signals
wire             SnOE;      // ZBT output enable
wire             SnCE;      // ZBT chip select
wire             SADVnLD;   // ZBT Mode pin
wire             SnWR;      // ZBT advance signal
wire             SnCKE;     // ZBT Clock enable signal
wire             SMODE;     // ZBT mode signal
// FLASH control signals
wire             FnOE;      // FLASH output enable
wire             FnWE;      // FLASH write enable
// misc signals
wire             PWRDNCLK1; // clock power-down control
wire             PWRDNCLK2; // clock power-down control
wire             TDO;       // test data out
wire      [19:2] SADDR;     // ZBT address bus

// -----------------------------------------------------------------------------
//
//                                  AHBAHBTop
//                                  =========
//
// -----------------------------------------------------------------------------
//
// Overview
// ========
// Top level VHDL for LM example
// Connects AHB slaves to the Integrator AHB busses
//
// Implements...
//  AHB Decoder
//  AHB Slave to master Mux
//  AHB SSRAM Controller
//  AHB APB bridge
//  APB Interrupt controller
//  APB Register peripheral
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------
wire        HSELAHBAPB;
// peripheral select - APB Peripherals

wire        HSELSSRAM;
// peripheral select - SSRAM controller

wire        HSELDefault;
// peripheral select - default slave

wire        HSELLOGICMODULE;
// LM being addressed - used for response enable

wire [31:0] HRDataApb;
// read data bus from APB bridge

wire [31:0] HRDATASSRAM;
// read data bus from SSRAM

wire [31:0] HRDATA;
// read data bus from mux to master(s)

wire        HReadyOutApb;
// hready response from APB bridge

wire        HReadyOutSsram;
// hready response from SSRAM

wire        HReadyOutDefault;
// hready response from default slave

wire  [1:0] HRespApb;
// hresp response from APB

wire  [1:0] HRESPSSRAM;
// hresp response from SSRAM

wire  [1:0] HRESPDefault;
// hresp response from default slave

wire [31:0] SWDATA;
// SSRAM write data bus

//wire        SDATAEN;	//marked by nelson
// tri-state enable for SSRAM data bus

wire        iHReadyOut;
// internal hready signal - feeds HREADYIn on slaves

wire  [1:0] iHRespOut;
// internal hresp from slave-master mux

// -----------------------------------------------------------------------------
// Register declarations
// -----------------------------------------------------------------------------
reg         ReadEnable;
// used to control tri-states on top level

reg         RespEnable;
// used to control tri-states on top level

// -----------------------------------------------------------------------------
// Function declarations
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
//
// Main body of code
// =================
//
// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// Instantiation of AHBDecoder
// -----------------------------------------------------------------------------
AHBDecoder uAHBDecoder                (
                    .HCLK             (HCLK),
                    .HRESETn          (HRESETn),
                    .HTRANS           (HTRANS),
                    .HREADYIn         (HREADY),
                    .HDRID            (HDRID),
                    .HADDR            (HADDR),
                    .HSELAHBAPB       (HSELAHBAPB),
                    .HSELSSRAM        (HSELSSRAM),
                    .HSELLOGICMODULE  (HSELLOGICMODULE),
                    .HSELDefault      (HSELDefault),
                    .HREADYOut        (HReadyOutDefault),
                    .HRESP            (HRESPDefault)
                    );

// -----------------------------------------------------------------------------
// Instantiation of AHBMuxS2M
// -----------------------------------------------------------------------------
AHBMuxS2M uAHBMuxS2M                  (
                    .HCLK             (HCLK),
                    .HRESETn          (HRESETn),
                    .HSELAHBAPB       (HSELAHBAPB),
                    .HSELSSRAM        (HSELSSRAM),
                    .HREADYAHBAPB     (HReadyOutApb),
                    .HREADYSSRAM      (HReadyOutSsram),
                    .HREADYDefault    (HReadyOutDefault),
                    .HRESPAHBAPB      (HRespApb),
                    .HRESPSSRAM       (HRESPSSRAM),
                    .HRESPDefault     (HRESPDefault),
                    .HREADYIn         (HREADY),
                    .HRDATAAHBAPB     (HRDataApb),
                    .HRDATASSRAM      (HRDATASSRAM),
                    .HREADYOut        (iHReadyOut),
                    .HRESP            (iHRespOut),
                    .HRDATA           (HRDATA)
                    );

// -----------------------------------------------------------------------------
// Instantiation of AHBAPBSys
// -----------------------------------------------------------------------------
AHBAPBSys uAHBAPBSys                  (
                    .HCLK             (HCLK),
                    .HRESETn          (HRESETn),
                    .HTRANS           (HTRANS),
                    .HWRITE           (HWRITE),
                    .HSELAHBAPB       (HSELAHBAPB),
                    .HREADYIn         (HREADY),
                    .nPBUTT           (nPBUTT),
                    .SW               (SW),
                    .HWDATA           (HWDATA),
                    .HADDR            (HADDR),
                    .HREADYOut        (HReadyOutApb),
                    .HRESP            (HRespApb),
                    .nLMINT           (nLMINT),
                    .CTRLCLK1         (CTRLCLK1),
                    .CTRLCLK2         (CTRLCLK2),
                    .LED              (LED),
                    .HRDATA           (HRDataApb)
                    );

// -----------------------------------------------------------------------------
// Instantiation of AHBZBTRAM
// -----------------------------------------------------------------------------
AHBZBTRAM uAHBZBTRAM                  (
                    .HCLK             (HCLK),
                    .HRESETn          (HRESETn),
                    .HSELSSRAM        (HSELSSRAM),
                    .HREADYIn         (HREADY),
                    .HTRANS           (HTRANS),
                    .HSIZE            (HSIZE),
                    .HWRITE           (HWRITE),
                    .HWDATA           (HWDATA),
                    .SRDATA           (SRDATA),
                    .HADDR            (HADDR),
                    .SCLK             (SCLK),
                    .HREADYOut        (HReadyOutSsram),
                    .HRESP            (HRESPSSRAM),
                    .SDATAEN          (SDATAEN),
                    .SnWBYTE          (SnWBYTE),
                    .SnOE             (SnOE),
                    .SnCE             (SnCE),
                    .SADVnLD          (SADVnLD),
                    .SnWR             (SnWR),
                    .SMODE            (SMODE),
                    .SnCKE            (SnCKE),
                    .SWDATA           (SWDATA),
                    .HRDATA           (HRDATASSRAM),
                    .SADDR            (SADDR)
                    );

/*
// -----------------------------------------------------------------------------
// Instantiation of MYIP	// added & modded by Nelson
// -----------------------------------------------------------------------------
MYIP 	uMYIP       (
                    .HCLK             (HCLK),
                    .HRESETn          (HRESETn),
                    .HSELMYIP         (HSELMYIP),
                    .HREADYIn         (HREADY),
                    .HTRANS           (HTRANS),
                    .HSIZE            (HSIZE),
                    .HWRITE           (HWRITE),
                    .HWDATA           (HWDATA),
                    .HADDR            (HADDR),
                    .HREADYOut        (HReadyOutMyip),
                    .HRESP            (HRESPMYIP),
                    .HRDATA           (HRDATAMYIP)
                    );
*/

// -----------------------------------------------------------------------------
// Integrator System Bus uses tri-state muxing of data and slave response
// signal respenable drives HRESP & HREADY out from this FPGA
// readenable HRDATA, HRESP and HREADY
// -----------------------------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin : p_ReadEnSeq
  if (HRESETn == 1'b0)
    begin
      ReadEnable  <= 1'b0;
      RespEnable  <= 1'b0;
    end
  else
    if (HREADY == 1'b1)
    // start new data phase when HREADY ='1'
      if (HSELLOGICMODULE == 1'b1)
        begin
          RespEnable  <= 1'b1;
          ReadEnable  <= ~(HWRITE);
        end
      else
        begin
          ReadEnable      <= 1'b0;
          RespEnable      <= 1'b0;
       end
end // p_ReadEnSeq

assign HREADYout	= iHReadyOut;
assign HREADY           = (RespEnable == 1'b1) ? iHReadyOut : 1'b1;//1'bz; //mod by Nelson

assign HRESP		= iHRespOut;
//assign HRESP            = (RespEnable == 1'b1) ? iHRespOut  : 2'bzz;

//assign HDATA            = (ReadEnable == 1'b1) ? HRDATA     : 32'hzzzzzzzz;

//assign SDATA            = (SDATAEN == 1'b1)    ? SWDATA     : 32'hzzzzzzzz; // marked by Nelson

// Ensure flash is disabled
assign FnOE             = 1'b1;
assign FnWE             = 1'b1;

// Route virtual JTAG signals through. If this module is stacked with something
// that uses a TAP controller, then it will still work OK
assign TDO              = TDI;
assign RTCK             = TCK;

// clk 1 running
assign PWRDNCLK1        = 1'b0;

// clk 2 disabled as this is the SYSCLK OUT from the LM, must be disabled
// when the LM is connected to a motherboard that supplies these clocks.
assign PWRDNCLK2        = 1'b1;

// there is no master in this FPGA to ever request the bus
//assign HBUSREQ          = 1'b0;

// there is no master in this FPGA to ever request locked cycles
assign HLOCK            = 1'b0;

endmodule

// --================================= End ===================================--
