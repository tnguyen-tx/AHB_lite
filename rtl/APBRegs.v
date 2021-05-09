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
//           This APB peripheral contains registers
//
// --=========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------

module APBRegs (
// Inputs
                PCLK,
                nRESET,
                PENABLE,
                PSEL,
                PWRITE,
                nPBUTT,
                SW,
                PWDATA,
                PA,
// Outputs
                CTRLCLK1,
                CTRLCLK2,
                REGSINT,
                LED,
                PRDATA
                );

// Inputs
input         PCLK;     // APB clock
input         nRESET;   // AMBA reset
input         PENABLE;  // APB enable
input         PSEL;     // APB select
input         PWRITE;   // APB read/write
input         nPBUTT;   // input that will be latched for an interrupt
                        // example
input   [7:0] SW;       // switches
input  [31:0] PWDATA;   // APB write data
input   [4:2] PA;       // APB address bus

// Outputs
output [18:0] CTRLCLK1; // sets frequency of CLK1
output [18:0] CTRLCLK2; // sets frequency of CLK2
output        REGSINT;  // interrupt output
output  [8:0] LED;      // LED control
output [31:0] PRDATA;   // APB read data

// Inputs
wire          PCLK;     // APB clock
wire          nRESET;   // AMBA reset
wire          PENABLE;  // APB enable
wire          PSEL;     // APB select
wire          PWRITE;   // APB read/write
wire          nPBUTT;   // input that will be latched for an interrupt example
wire    [7:0] SW;       // switches
wire   [31:0] PWDATA;   // APB write data
wire    [4:2] PA;       // APB address bus

// Outputs
wire   [18:0] CTRLCLK1; // sets frequency of CLK1
wire   [18:0] CTRLCLK2; // sets frequency of CLK2
wire          REGSINT;  // interrupt output
wire    [8:0] LED;      // LED control
reg    [31:0] PRDATA;   // APB read data


// -----------------------------------------------------------------------------
//
//                                   APBRegs
//                                   =======
//
// -----------------------------------------------------------------------------
//
// Overview
// ========
// This APB peripheral contains registers to...
// * program & lock the two clock oscillators
// * write to the general purpose LEDs
// * clear push button interrupt
// * read the general purpose switches
//
// Certain registers are protected by the LOCK register. You must write 0xA05F
// to the lock register to enable the following registers to be modified:
//
//   LM_OSC1
//   LM_OSC2
//
// Provides nLMINT to the top level & registers all interrupt sources
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------
// 1 MHz default clock values
`define OSC1_VECTOR      19'b1100111110000000100

`define OSC2_VECTOR      19'b1100111110000000100

// Lock register key 0xA05F
`define LOCK_KEY         16'b1010000001011111

// Address decoding
`define LM_OSC1          3'b000
// read/write

`define LM_OSC2          3'b001
// read/write

`define LM_LOCK          3'b010
// read/write

`define LM_LEDS          3'b011
// read/write

`define LM_INT           3'b100
// read/write

`define LM_SW            3'b101
// read only

// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------
wire  [7:0] LmSwReg;
// Switch register

wire        Locked;
// Registers are Locked

// -----------------------------------------------------------------------------
// Register declarations
// -----------------------------------------------------------------------------
reg  [18:0] LmOscReg1;
// Oscillator register1

reg  [18:0] LmOscReg2;
// Oscillator register2

reg  [15:0] LmLckReg;
// Lock register

reg   [8:0] LmLedsReg;
// LED register

reg         LmIntReg;
// INT register

reg  [31:0] NextPRDATA;
// read data

// -----------------------------------------------------------------------------
// Function declarations
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//
// Main body of code
// =================
//
// -----------------------------------------------------------------------------

// Locked signal protects registers that could be accidently changed
assign Locked           = (LmLckReg == `LOCK_KEY) ? 1'b0 : 1'b1;

// switch register is read only
assign LmSwReg          = SW;

// -----------------------------------------------------------------------------
// Lock register is read/write
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_LdLckRegSeq
  if (nRESET == 1'b0)
    LmLckReg     <= 16'h0000;
  else
    if ((PSEL & PWRITE & PENABLE) == 1'b1)
      if (PA == `LM_LOCK)
        LmLckReg <= PWDATA[15:0];
end // p_LdLckRegSeq

// -----------------------------------------------------------------------------
// Oscillator1 register is read/write, protected by lock register
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_LdOscRegSeq1
  if (nRESET == 1'b0)
    LmOscReg1     <= `OSC1_VECTOR;
  else
    if ((PSEL & PWRITE & PENABLE & ~Locked) == 1'b1)
      if (PA == `LM_OSC1)
        LmOscReg1 <= PWDATA[18:0];
end // p_LdOscRegSeq1

assign CTRLCLK1         = LmOscReg1;

// -----------------------------------------------------------------------------
// Oscillator2 register is read/write, protected by lock register
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_LdOscRegSeq2
  if (nRESET == 1'b0)
    LmOscReg2     <= `OSC2_VECTOR;
  else
    if ((PSEL & PWRITE & PENABLE & ~Locked) == 1'b1)
      if (PA == `LM_OSC2)
        LmOscReg2 <= PWDATA[18:0];
end // p_LdOscRegSeq2

assign CTRLCLK2         = LmOscReg2;

// -----------------------------------------------------------------------------
// LEDS register is read/write
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_LdLEDSRegSeq
  if (nRESET == 1'b0)
    // put a pattern on them
    LmLedsReg     <= 9'b101010101;
  else
    if ((PSEL & PWRITE & PENABLE) == 1'b1)
      if (PA == `LM_LEDS)
        LmLedsReg <= PWDATA[8:0];
end // p_LdLEDSRegSeq

assign LED              = LmLedsReg;

// -----------------------------------------------------------------------------
// interrupt is latched on rising edge of nPBUTTutton input
// INT register is read/write(to clear int)
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET or negedge nPBUTT)
begin : p_LdIntRegSeq
  if (nRESET == 1'b0)
    LmIntReg     <= 1'b0;
  else if (nPBUTT == 1'b0)
    LmIntReg     <= 1'b1;
  else
    if ((PSEL & PWRITE & PENABLE) == 1'b1)
      if (PA == `LM_INT)
        LmIntReg <= PWDATA[0];
end // p_LdIntRegSeq

assign REGSINT          = LmIntReg;

// -----------------------------------------------------------------------------
// Read registers
// -----------------------------------------------------------------------------
always @(PA or LmOscReg1 or LmOscReg2 or LmLckReg or Locked or LmLedsReg or
         LmIntReg or LmSwReg)
begin : p_GenNPRDATAComb
  NextPRDATA       = 32'h00000000;
  case (PA)
    `LM_OSC1 :
       NextPRDATA[18:0]  = LmOscReg1;
    `LM_OSC2 :
       NextPRDATA[18:0]  = LmOscReg2;
    `LM_LOCK :
      begin
        NextPRDATA[15:0] = LmLckReg;
        NextPRDATA[16]   = Locked;
      end
    `LM_LEDS :
       NextPRDATA[8:0]   = LmLedsReg;
    `LM_INT :
       NextPRDATA[0]     = LmIntReg;
    `LM_SW :
       NextPRDATA[7:0]   = LmSwReg;
    default :
       NextPRDATA[31:0]  = 32'h00000000;
  endcase
end // p_GenNPRDATAComb

// -----------------------------------------------------------------------------
// When the peripheral is not being accessed, '0's are driven
// on the Read Databus (PRDATA) so as not to place any restrictions
// on the method of external bus connection. The external data buses of the
// peripherals on the APB may then be connected to the ASB-to-APB bridge using
// Muxed or ORed bus connection method.
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_RdSeq
  if (nRESET == 1'b0)
    PRDATA <= 32'h00000000;
  else
    PRDATA <= NextPRDATA;
end // p_RdSeq

endmodule
// --================================== End ==================================--
