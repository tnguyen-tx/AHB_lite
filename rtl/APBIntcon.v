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
//           Provides nLMINT to the top level & registers all interrupt sources
//
// --=========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------

module APBIntcon (
// Inputs
                  PCLK,
                  nRESET,
                  PENABLE,
                  PSEL,
                  PWRITE,
                  INTSRC,
                  PWDATA,
                  PADDR,
// Outputs
                  nLMINT,
                  PRDATA
                  );

// Inputs
input        PCLK;    // APB peripheral clock
input        nRESET;  // reset input
input        PENABLE; // APB peripheral enable
input        PSEL;    // APB peripheral select
input        PWRITE;  // APB write
input  [7:4] INTSRC;  // interrupt source vector
input  [7:0] PWDATA;  // APB write data bus
input  [7:2] PADDR;   // APB address bus

// Outputs
output       nLMINT;  // interrupt output
output [7:0] PRDATA;  // APB read data bus

// Inputs
wire         PCLK;    // APB peripheral clock
wire         nRESET;  // reset input
wire         PENABLE; // APB peripheral enable
wire         PSEL;    // APB peripheral select
wire         PWRITE;  // APB write
wire   [7:4] INTSRC;  // interrupt source vector
wire   [7:0] PWDATA;  // APB write data bus
wire   [7:2] PADDR;   // APB address bus

// Outputs
reg          nLMINT;  // interrupt output
reg    [7:0] PRDATA;  // APB read data bus


// -----------------------------------------------------------------------------
//
//                                  APBIntcon
//                                  =========
//
// -----------------------------------------------------------------------------
//
// Overview
// ========
// Provides nLMINT to the top level & registers all interrupt sources
//
// -----------------------------------------------------------------------------

// ---------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------

// Number if interrupt sources
// This example only uses 1 real & 4 soft interrupts, the AxBAPBSys block
// assigns the top three as static zeros to show where to concatenate IRQ
// sources
`define NUMLMINTS        8

// -----------------------------------------------------------------------------
//  Address offset constants - see Reference Peripheral specification
// -----------------------------------------------------------------------------
// bits 4:2 register
// bit 5 irq/fiq
// bit 7:6 processor number
`define LM_ISTAT         4'b0000
`define LM_IRSTAT        4'b0001
`define LM_IENSET        4'b0010
`define LM_IENCLR        4'b0011
`define LM_SOFTINT       4'b0100

// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------
wire [`NUMLMINTS-1:0] LmIntStReg;
// Interrupt status register

wire                  DataBusEn;
// Data bus Enable signal

wire [`NUMLMINTS-1:0] NextPRDATA;
// D-input of PRDATA

wire                  inLMINT;
// Internal copy of nLMINT

// -----------------------------------------------------------------------------
// Register declarations
// -----------------------------------------------------------------------------
reg             [3:0] SoftIntReg;
// Soft Interrupt register

reg [`NUMLMINTS-1:0] RawIntReg;
// Raw Interrupt register

reg [`NUMLMINTS-1:0] LmIntEnReg;
// Interrupt Enable Register

// -----------------------------------------------------------------------------
// Function declarations
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// OrVectorIrq :
// -------------
// This function performs logical OR of all inputs
// -----------------------------------------------------------------------------
function OrVectorIrq;
input [`NUMLMINTS-1:0] InVector;

reg                    Temp; // Temporary variable
integer                i;    // Temorary variable

begin
  Temp   = InVector[0];
  for (i = `NUMLMINTS-1; i >= 1; i =  i - 1)
    Temp = Temp | InVector[i];
  OrVectorIrq = Temp;
end
endfunction

// -----------------------------------------------------------------------------
//
// Main body of code
// =================
//
// -----------------------------------------------------------------------------

// nLMINT output is the logical OR of all enabled interrupt sources
assign inLMINT          = OrVectorIrq(LmIntStReg);

// -----------------------------------------------------------------------------
// synchronize nLMINT to the rising edge of the clock and
// ensure interrupts are cleared during reset
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_SyncnLMINT
  if (nRESET == 1'b0)
    nLMINT <= 1'b1;
  else
    nLMINT <= ~(inLMINT);
end // p_SyncnLMINT

// Status registers are the logical AND of the pending interrupts
// and the appropriate enable register
assign LmIntStReg       = RawIntReg & LmIntEnReg;

// -----------------------------------------------------------------------------
// Raw interrupts are registered on the rising edge of the clock
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_SyncRawIntSeq
  if (nRESET == 1'b0)
    begin
      RawIntReg[`NUMLMINTS-1:4] <= {`NUMLMINTS -1 {1'b0}};
      RawIntReg[3:0]            <= 4'b0000;
    end
  else
    begin
      RawIntReg[`NUMLMINTS-1:4] <= INTSRC[`NUMLMINTS-1:4];
      RawIntReg[3:0]            <= SoftIntReg;
    end
 
end // p_SyncRawIntSeq


// -----------------------------------------------------------------------------
// Enable registers have seperate set and clear operations
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_WrEnRegSeq
  if (nRESET == 1'b0)
    LmIntEnReg     <= {`NUMLMINTS -1 {1'b0}};
  else
    if ((PSEL & PWRITE & PENABLE) == 1'b1)
      begin

        // set IRQ enable bits
        if (PADDR[5:2] == `LM_IENSET)
          LmIntEnReg <= PWDATA[`NUMLMINTS-1:0] | LmIntEnReg;

        // clear IRQ enable bits
        if (PADDR[5:2] == `LM_IENCLR)
          LmIntEnReg <= (~(PWDATA[`NUMLMINTS-1:0])) & LmIntEnReg;
      end

end // p_WrEnRegSeq

// -----------------------------------------------------------------------------
// Soft interrupt register
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_WrSoftRegSeq
  if (nRESET == 1'b0)
    SoftIntReg   <= 4'b0000;
  else
    if (((PSEL & PWRITE & PENABLE) == 1'b1) & (PADDR[5:2] == `LM_SOFTINT))
      SoftIntReg <= PWDATA[3:0];
end // p_WrSoftRegSeq

// drive PD when registers selected for read
assign DataBusEn        = PSEL & ( ~PWRITE);

// multiplexor to read registers depending on address
assign NextPRDATA        = ((PADDR[5:2] == `LM_IRSTAT) & (DataBusEn == 1'b1)) ?
                           RawIntReg : (((PADDR[5:2] == `LM_ISTAT) &
                                        (DataBusEn == 1'b1)) ?
                           LmIntStReg : (((PADDR[5:2] == `LM_IENSET) &
                                         (DataBusEn == 1'b1)) ?
                           LmIntEnReg : {`NUMLMINTS -1{1'b0}}));

// -----------------------------------------------------------------------------
// When the peripheral is not being accessed, '0's are driven
// on the Read Databus (PRDATA) so as not to place any restrictions
// on the method of external bus connection. The external data buses of the
// peripherals on the APB may then be connected to the ASB-to-APB bridge using
// Muxed or ORed bus connection method.
// -----------------------------------------------------------------------------
always @(posedge PCLK or negedge nRESET)
begin : p_RdRegSeq
  if (nRESET == 1'b0)
    PRDATA <= {`NUMLMINTS - 1{1'b0}};
  else
    PRDATA <= NextPRDATA;
end // p_RdRegSeq

endmodule

// --================================== End ==================================--
