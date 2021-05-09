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
//           Bridge component to connect APB system to AHB buses.
//
// --=========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------

module AHB2APB (
// Inputs
                HCLK,
                HRESETn,
                HTRANS,
                HWRITE,
                HSELAHBAPB,
                HREADYIn,
                PRDATA,
                HWDATA,
                HADDR,
// Outputs
                PENABLE,
                HREADYOut,
                HRESP,
                PWRITE,
                PSELREGS,
                PSELINTC,
                PWDATA,
                HRDATA,
                PADDR
                );

// Inputs
input         HCLK;       // system bus clock
input         HRESETn;    // reset input (active low)
input   [1:0] HTRANS;     // AHB transfer type
input         HWRITE;     // AHB hwrite
input         HSELAHBAPB; // AHB peripheral select
input         HREADYIn;   // AHB ready input
input  [31:0] PRDATA;     // APB read data bus
input  [31:0] HWDATA;     // AHB write data bus
input  [31:0] HADDR;      // AHB address bus

// Outputs
output        PENABLE;    // APB peripheral enable
output        HREADYOut;  // AHB ready output to S->M mux
output  [1:0] HRESP;      // AHB response
output        PWRITE;     // Peripheral bus Write
output        PSELREGS;   // Peripheral select - register peripheral
output        PSELINTC;   // Peripheral select - interrupt controller
output [31:0] PWDATA;     // APB write data bus
output [31:0] HRDATA;     // AHB read data bus
output [31:0] PADDR;      // APB address bus

// Inputs
wire          HCLK;       // system bus clock
wire          HRESETn;    // reset input (active low)
wire    [1:0] HTRANS;     // AHB transfer type
wire          HWRITE;     // AHB hwrite
wire          HSELAHBAPB; // AHB peripheral select
wire          HREADYIn;   // AHB ready input
wire   [31:0] PRDATA;     // APB read data bus
wire   [31:0] HWDATA;     // AHB write data bus
wire   [31:0] HADDR;      // AHB address bus

// Outputs
wire          PENABLE;    // APB peripheral enable
wire          HREADYOut;  // AHB ready output to S->M mux
wire    [1:0] HRESP;      // AHB response
wire          PWRITE;     // Peripheral bus Write
wire          PSELREGS;   // Peripheral select - register peripheral
wire          PSELINTC;   // Peripheral select - interrupt controller
wire   [31:0] HRDATA;     // AHB read data bus
wire   [31:0] PADDR;      // APB address bus
reg    [31:0] PWDATA;     // APB write data bus

// -----------------------------------------------------------------------------
//
//                                   AHB2APB
//                                   =======
//
// -----------------------------------------------------------------------------
//
// Overview
// ========
// Bridge component to connect APB system to AHB buses
// Provides chip select lines and enable signal to all APB peripherals.
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------
// This constant defines the size of the peripheral address bus:
`define PADDRWIDTH       16

// APBIF states:
`define ST_IDLE          3'b000
`define ST_WWAIT         3'b001
`define ST_WRITE         3'b010
`define ST_READ          3'b011
`define ST_ENABLE        3'b100

// constants for APB address decoding
`define INTCBASE         4'b0001
`define REGSBASE         4'b0000

// HTRANS transfer type signal encoding
`define TRN_IDLE         2'b00
`define TRN_BUSY         2'b01
`define TRN_NONSEQ       2'b10
`define TRN_SEQ          2'b11

// HRESP transfer response signal encoding
`define RSP_OKAY         2'b00
`define RSP_ERROR        2'b01
`define RSP_RETRY        2'b10
`define RSP_SPLIT        2'b11

// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------
wire        Valid;
// Module is selected with Valid transfer

wire        RegValid;
// Module was selected with valid transfer

wire        AddrCRegEn;
// Enable for address and control registers

wire [31:0] HAddrMux;
// HADDR multiplexor

wire        WrBurst;
// Write burst detection

wire        Wr2Rd;
// Write to read detection

wire        ApbEn;
// High if in either READ or WRITE state

wire        HReadyNext;
// HREADYOut register input

wire        PWDATAEn;
// PWDATA Register enable

wire        iPENABLE;
// Internal PENABLE

wire        PSelRes;
// PSEL reset

wire        NextPWRITE;
// PWRITE register input

// -----------------------------------------------------------------------------
// Register declarations
// -----------------------------------------------------------------------------
reg         HSelReg;
// HSELAHBAPB register

reg         RegValidPrev;
// Previous RegValid value

reg   [1:0] HTransReg;
// HTRANS register

reg         HWriteReg;
// HWRITE register

reg         PSELREGSInt;
// Internal PSELREGS

reg         PSELINTCInt;
// Internal PSELINTC

reg         WrBurstReg;
// Write burst register

reg         Wr2RdReg;
// Write to read detection register

reg   [2:0] NextState;
// State machine

reg   [2:0] CurrentState;
// Current state

reg         iHREADYOut;
// HREADYOut register

reg         iPSELREGS;
// Internal PSEL outputs

reg         iPSELINTC;
// Internal PSEL outputs

reg   [`PADDRWIDTH-1:0] iPADDR;
// Registered internal PADDR

reg         iPWRITE;
// Registered internal PWRITE

reg  [31:0] HAddrReg;
// HADDR register

// -----------------------------------------------------------------------------
// Function declarations
// -----------------------------------------------------------------------------
//
// Main body of code
// =================
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Valid transfer detection
// The slave must only respond to a valid transfer, so this must be detected.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_HSelRegSeq
  if (HRESETn == 1'b0)
    HSelReg   <= 1'b0;
  else
    if (HREADYIn == 1'b1)
      HSelReg <= HSELAHBAPB;
end // p_HSelRegSeq

// Valid AHB transfers only take place when a non-sequential or sequential
// transfer is shown on HTRANS - an idle or busy transfer should be ignored.
assign Valid            = ((HSELAHBAPB == 1'b1) & (HREADYIn == 1'b1) &
                           ((HTRANS == `TRN_NONSEQ) | (HTRANS == `TRN_SEQ))) ?
                          1'b1 : 1'b0;

assign RegValid         = ((HSelReg == 1'b1) & ((HTransReg == `TRN_NONSEQ) |
                           (HTransReg == `TRN_SEQ))) ?
                          1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// This register is used in the detection of a sequence of transfers where
// there is an APB transfer, followed by a non-APB transfer and another APB
// transfer. HREADYIn is not used as an enable to avoid extra APB cycles from
// being inserted.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_RegValidPrevSeq
  if (HRESETn == 1'b0)
    RegValidPrev <= 1'b0;
  else
    RegValidPrev <= RegValid;
end // p_RegValidPrevSeq

assign AddrCRegEn       = HSELAHBAPB & HREADYIn;

// -----------------------------------------------------------------------------
// Address and control registers
// Registers are used to store the address and control signals from the address
// phase for use in the data phase of the transfer.
// Only enabled when the HREADYIn input is HIGH and the module is addressed.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_AddrCntRegSeq
  if (HRESETn == 1'b0)
    begin
      HAddrReg    <= 32'h00000000;
      HTransReg   <= 2'b00;
      HWriteReg   <= 1'b0;
    end
  else
    if (AddrCRegEn == 1'b1)
      begin
        HAddrReg  <= HADDR;
        HTransReg <= HTRANS;
        HWriteReg <= HWRITE;
      end
end // p_AddrCntRegSeq

// Internally, the address used depends on the current cycle being a read or a
// write, due to the different timing for each type of transfer.
// As a write transfer does not start until the write data has been driven onto
// HWDATA, HADDR will contain the address for the next transfer, so the
// address for a write transfer is always pipelined. The HAddrReg registers
// are used as the pipeline, as they will always hold the previous AHB
// address.
// So, a multiplexor is needed to select the address source depending on the
// current transfer type:
// HADDR for a read cycle.
// HAddrReg for a write cycle.
// HAddrReg is also selected when a non-sequential read (or write) is performed
// when the APB has just started a write transfer, as by the time the current
// APB cycle has finished, the AHB address will have moved onto the next
// transfer.
// HAddrReg is used as the default state as it will change less often than the
// HADDR input.
//
// HAddrMux is used to generate the PSELxInt signals and PADDR.

assign HAddrMux         = ((RegValid == 1'b1) & (RegValidPrev == 1'b0) &
                           (CurrentState == `ST_ENABLE)) ?
                          HAddrReg   : ((NextState == `ST_READ) ?
                          HADDR      : HAddrReg);

// -----------------------------------------------------------------------------
// APB address decoding for slave devices
// Decodes the address from HAddrMux, which only changes during a read or write
// cycle.
// When an address is used that is not in any of the ranges specified,
// operation of the system continues, but no PSEL lines are set, so no
// peripherals are selected during the read/write transfer.
// Operation of PWDATA, PWRITE, PENABLE and PADDR continues as normal.
// -----------------------------------------------------------------------------
always @(HAddrMux or HRESETn)
begin : p_AddrDecodeComb
  if (HRESETn == 1'b0)
    begin
      PSELREGSInt = 1'b0;
      PSELINTCInt = 1'b0;
    end
  else if (HAddrMux[27:24] == `REGSBASE)
    begin
      PSELREGSInt = 1'b1;
      PSELINTCInt = 1'b0;
    end
  else if (HAddrMux[27:24] == `INTCBASE)
    begin
      PSELINTCInt = 1'b1;
      PSELREGSInt = 1'b0;
    end
  else
    begin
      PSELREGSInt = 1'b0;
      PSELINTCInt = 1'b0;
    end
end // p_AddrDecodeComb

assign WrBurst          = ((Valid == 1'b1) & (RegValid == 1'b1) &
                           (HWRITE == 1'b1)) ? 1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// Write Burst detection
// The operation of the bridge is different when doing a single write operation
// to a burst of writes, so need to be able to tell when a burst of writes is
// being performed.
// It is stored in a register to allow it to still be valid when the AHB starts
// on the next transfer at the end of a burst.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_WrBurstSeq
  if (HRESETn == 1'b0)
    WrBurstReg   <= 1'b0;
  else
    if (HREADYIn == 1'b1)
      WrBurstReg <= WrBurst;
end // p_WrBurstSeq

assign Wr2Rd            = ((CurrentState == `ST_WRITE) &
                           (HTransReg == `TRN_SEQ) & (HWriteReg == 1'b0)) ?
                          1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// Write to read transfer
// When a sequential transfer changes from a write to a read then an extra wait
// state must be added due to the extra cycle taken to start a write transfer,
// to allow time for the read data to be generated before being sampled on the
// AHB.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_Wr2RdSeq
  if (HRESETn == 1'b0)
    Wr2RdReg <= 1'b0;
  else
    Wr2RdReg <= Wr2Rd;
end // p_Wr2RdSeq

// -----------------------------------------------------------------------------
// Next state logic for APB state machine
// Generates next state from CurrentState and AHB inputs.

// A normal non-seq transfer occurs on the AHB when the APB is not performing
// any transfers.
// A seq transfer occurs when the previous transfer on the AHB was also an APB
// transfer.
// A fast non-seq transfer is where there is one non-APB unwaited AHB cycle
// between two APB transfers, so that the APB has just started the previous
// transfer (current state is `ST_READ or `ST_WRITE) when the next transfer
// appears on the AHB.
// A slow non-seq is where a new APB transfer is started on the AHB when the
// current state is ST_ENABLE, following a non-APB transfer.
// -----------------------------------------------------------------------------
always @(CurrentState or Valid or HWRITE or WrBurstReg or Wr2RdReg or
         RegValid or RegValidPrev or HWriteReg)
begin : p_NextStateComb
  case (CurrentState)

    // Idle state
    `ST_IDLE :
      if (Valid == 1'b1)
        // Non-seq, so enter write wait state
        if (HWRITE == 1'b1)
           NextState = `ST_WWAIT;

        // Non-seq, so straight to read state
        else
           NextState = `ST_READ;
      else
        NextState    = `ST_IDLE;

    // Start of APB read cycle
    `ST_READ :
       NextState     = `ST_ENABLE;

    // Hold for one cycle before write
    `ST_WWAIT :
       NextState     = `ST_WRITE;

    // Start of APB write cycle
    `ST_WRITE :
       NextState     = `ST_ENABLE;

    // Enable cycle to complete transaction
    `ST_ENABLE :
      if (WrBurstReg == 1'b1)
        NextState    = `ST_WRITE;
      else if (RegValid == 1'b1 & RegValidPrev == 1'b0)
        if (HWriteReg == 1'b1)
          NextState  = `ST_WRITE;
        else
          NextState  = `ST_READ;
      else if (Wr2RdReg == 1'b1)
        NextState    = `ST_READ;
      else if (Valid == 1'b1)
        if (HWRITE == 1'b1)
          NextState  = `ST_WWAIT;
        else
          NextState  = `ST_READ;
      else
        NextState    = `ST_IDLE;

    // Return to idle on FSM error
    default :
       NextState     = `ST_IDLE;

  endcase
end // p_NextStateComb

// -----------------------------------------------------------------------------
// State machine
// Changes state on rising edge of HCLK.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_CurrentStSeq
  if (HRESETn == 1'b0)
    CurrentState <= `ST_IDLE;
  else
    CurrentState <= NextState;
end // p_CurrentStSeq

// -----------------------------------------------------------------------------
// APB enable generation
// ApbEn set when preforming an access on the APB, that is, when the current
// state is `ST_READ or ST_WRITE, and is used to enable the APB output registers.
// -----------------------------------------------------------------------------
assign ApbEn            = ((NextState == `ST_READ) | (NextState == `ST_WRITE)) ?
                          1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// HREADYOut generation
// -----------------------------------------------------------------------------
assign HReadyNext       = (((NextState == `ST_WRITE) & (Valid == 1'b1) &
                            (HSELAHBAPB == 1'b1)) | ((NextState == `ST_ENABLE) &
                            (Valid == 1'b1) & (RegValid == 1'b0) &
                            (HWRITE == 1'b0)) | (Wr2Rd == 1'b1) |
                            (NextState == `ST_READ)) ? 1'b0 : 1'b1;

// -----------------------------------------------------------------------------
// A registered version of HREADYOut is used to improve output timing.
// Wait states are inserted during:
// ST_WRITE when a write follows a read or a write.
// ST_ENABLE when a read follows an AHB access that was not to the APB.
// ST_ENABLE when a read follows a write (Wr2Rd set).
// ST_READ.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_iHREADYOutSeq
  if (HRESETn == 1'b0)
    iHREADYOut <= 1'b0;
  else
    iHREADYOut <= HReadyNext;
end // p_iHREADYOutSeq

// -----------------------------------------------------------------------------
// Registered HWDATA for writes (PWDATA)
// -----------------------------------------------------------------------------
assign PWDATAEn         = (NextState == `ST_WRITE) ? 1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// Write wait state allows a register to be used to hold PWDATA.
// Register enabled when in ST_WRITE.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_PWDATASeq
  if (HRESETn == 1'b0)
    PWDATA   <= 32'h00000000;
  else
    if (PWDATAEn == 1'b1)
      PWDATA <= HWDATA;
end // p_PWDATASeq

// -----------------------------------------------------------------------------
// Internal PENABLE generation
// This is set to be a direct copy of one of the FSM bits. This should be
//  changed if the state encoding of the FSM is altered from the default
// -----------------------------------------------------------------------------
assign iPENABLE         = CurrentState[2];

// -----------------------------------------------------------------------------
// iPSEL generation
// Synchronous reset used to clear the PSEL outputs at the end of a transfer.
// This logic is used to reduce the combinational output path from HTRANS to
// the PSELxx registers, but it is functionally equivalent to:
// -----------------------------------------------------------------------------
assign PSelRes          = ((CurrentState == `ST_ENABLE) & (WrBurstReg == 1'b0) &
                           (Wr2RdReg == 1'b0) & ~((RegValid == 1'b1) &
                           (RegValidPrev == 1'b0)) & ~((Valid == 1'b1) &
                           (HWRITE == 1'b0))) ? 1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// Drives PSEL outputs with internal signals or set LOW on reset:
// Set outputs with internal values when in ST_READ or ST_WRITE states
// Reset outputs on system reset or at end of transfer (PSelRes HIGH)
// Hold outputs when in ST_ENABLE state (ApbEn LOW)
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_PSELSeq
  if (HRESETn == 1'b0)
    begin
      iPSELREGS   <= 1'b0;
      iPSELINTC   <= 1'b0;
    end
  else
    if (ApbEn == 1'b1)
      begin
        iPSELREGS <= PSELREGSInt;
        iPSELINTC <= PSELINTCInt;
      end
    else if (PSelRes == 1'b1)
      begin
        iPSELREGS <= 1'b0;
        iPSELINTC <= 1'b0;
      end
    else
      begin
        iPSELREGS <= iPSELREGS;
        iPSELINTC <= iPSELINTC;
      end
end // p_PSELSeq

// -----------------------------------------------------------------------------
// Registered HADDR for reads and writes (iPADDR)
// HAddrMux is used as the generation time of the APB address is different for
// reads and writes, so both the direct and registered HADDR input need to be
// used.
// HAddrMux is captured by an ApbEn enabled register to generate iPADDR.
// Signal iPADDR is used so that only (PADDRWIDTH - 1) of PADDR is driven.
// iPADDR driven on State Machine change to ST_READ or ST_WRITE, with reset
// to zero.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_iPADDRSeq
  if (HRESETn == 1'b0)
    iPADDR   <= {`PADDRWIDTH - 1{1'b0}};
  else
    if (ApbEn == 1'b1)
      iPADDR <= HAddrMux[`PADDRWIDTH - 1:0];
end // p_iPADDRSeq

// -----------------------------------------------------------------------------
// iPWRITE generation
// -----------------------------------------------------------------------------
assign NextPWRITE       = (NextState == `ST_WRITE) ? 1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// NextPWRITE is captured by an ApbEn enabled register to generate iPWRITE, and
// is generated from NextState (set HIGH during a write cycle).
// PWRITE output only changes when APB is accessed.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_iPWRITESeq
  if (HRESETn == 1'b0)
    iPWRITE   <= 1'b0;
  else
    if (ApbEn == 1'b1)
      iPWRITE <= NextPWRITE;
end // p_iPWRITESeq

// -----------------------------------------------------------------------------
// APB output drivers
// Drive outputs with internal signals.
// -----------------------------------------------------------------------------
assign PADDR[`PADDRWIDTH - 1:0] = iPADDR;

assign PWRITE           = iPWRITE;

assign PENABLE          = iPENABLE;

assign PSELREGS         = iPSELREGS;

assign PSELINTC         = iPSELINTC;

// -----------------------------------------------------------------------------
// AHB output drivers
// PRDATA is only ever driven during a read, so it can be directly copied to
// HRDATA to reduce the output data delay onto the AHB.
// -----------------------------------------------------------------------------
assign HRDATA           = PRDATA;

// -----------------------------------------------------------------------------
// Drives the output port with the internal version, and sets it LOW at all
//  other times when the module is not selected.
// -----------------------------------------------------------------------------
assign HREADYOut        = iHREADYOut;

// -----------------------------------------------------------------------------
// The response will always be OKAY to show that the transfer has been performed
// successfully.
// -----------------------------------------------------------------------------
assign HRESP            = `RSP_OKAY;

endmodule
// --================================== End ==================================--
