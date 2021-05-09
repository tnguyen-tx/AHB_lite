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
//           Gives HSELx module select outputs to the AHB system slaves
//
// --=========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------

module AHBDecoder (
// Inputs
                   HCLK,
                   HRESETn,
                   HTRANS,
                   HREADYIn,
                   HDRID,
                   HADDR,
// Outputs
                   HSELAHBAPB,
                   HSELSSRAM,
                   HSELLOGICMODULE,
                   HSELDefault,
                   HREADYOut,
                   HRESP
                  );

// Inputs
input         HCLK;            // system bus clock
input         HRESETn;         // reset input (active low)
input   [1:0] HTRANS;          // AHB transfer type
input         HREADYIn;        // AHB ready input
input   [3:0] HDRID;           // header ID (stack position)
input  [31:0] HADDR;           // AHB address bus
// Outputs
output        HSELAHBAPB;      // peripheral select - APB Peripherals
output        HSELSSRAM;       // peripheral select - SSRAM controller
output        HSELLOGICMODULE; // LM being addressed - used for response
                               // enable in top level
output        HSELDefault;     // peripheral select - default slave
output        HREADYOut;       // AHB ready output to S->M mux
output  [1:0] HRESP;           // AHB Response signal

// Inputs
wire          HCLK;            // system bus clock
wire          HRESETn;         // reset input (active low)
wire    [1:0] HTRANS;          // AHB transfer type
wire          HREADYIn;        // AHB ready input
wire    [3:0] HDRID;           // header ID (stack position)
wire   [31:0] HADDR;           // AHB address bus

// Outputs
wire          HSELAHBAPB;       // peripheral select - APB Peripherals
wire          HSELSSRAM;        // peripheral select - SSRAM controller
wire          HSELLOGICMODULE;  // LM being addressed - used for response
                                // enable in top level
wire          HSELDefault;      // peripheral select - default slave
wire          HREADYOut;        // AHB ready output to S->M mux
reg     [1:0] HRESP;            // AHB Response signal

// -----------------------------------------------------------------------------
//
//                                 AHBDecoder
//                                 ==========
//
// -----------------------------------------------------------------------------
//
// Overview
// ========
// Provides the HSELx module select outputs to the AHB system slaves, and
// controls the read data multiplexor. This module is specific to a particular
// implementation.
//
// The decoder block also contains the default slave. The hready and the
// hresp outputs of the decoder are used when the APB bridge or the SSRAM
// controller are not being addressed.
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------
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
wire       iHSELAHBAPB;
// Internal copy of HSELAHBAPB

wire       iHSELSSRAM;
// Internal copy of HSELSSRAM

wire       iHSELLOGICMODULE;
// Internal copy of HSELLOGICMODULE

wire       iHSELDefault;
// Internal copy of HSELDefault

wire [1:0] NextHRESP;
// D-input of HRESP

wire       NextHREADY;
// D-input of HREADY

// -----------------------------------------------------------------------------
// Register declarations
// -----------------------------------------------------------------------------
reg        iHREADYOut;
// Internal copy of HREADYOut

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
// AHB address decoding for slave selection and read data multiplexor control
// -----------------------------------------------------------------------------
assign iHSELLOGICMODULE = ((((HDRID == 4'b1110) & (HADDR[31:28] == 4'b1100)) |
                            ((HDRID == 4'b0111) & (HADDR[31:28] == 4'b1101)) |
                            ((HDRID == 4'b1011) & (HADDR[31:28] == 4'b1110)) |
                            ((HDRID == 4'b1101) & (HADDR[31:28] == 4'b1111))) &
                            (HRESETn == 1'b1)) ? 1'b1 : 1'b0;

assign iHSELAHBAPB      = ((iHSELLOGICMODULE == 1'b1) &
                           (HADDR[27:25] == 3'b000)) ? 1'b1 : 1'b0;

assign iHSELSSRAM       = ((iHSELLOGICMODULE == 1'b1) &
                           (HADDR[27:20] == 8'b00100000)) ? 1'b1 : 1'b0;

assign iHSELDefault     = ((iHSELLOGICMODULE == 1'b1) &
                           ~(HADDR[27:25] == 3'b000) &
                           ~(HADDR[27:20] == 8'b00100000)) ? 1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// Default slave output drivers
// -----------------------------------------------------------------------------
assign NextHRESP        = (((HTRANS == `TRN_NONSEQ) | (HTRANS == `TRN_SEQ)) &
                           (iHSELDefault == 1'b1)) ? `RSP_ERROR : `RSP_OKAY;

// -----------------------------------------------------------------------------
// When an undefined area of the memory map is accessed, or an invalid address
// is driven onto the address bus, the default slave outputs are selected and
// passed to the current bus master.
// An OKAY response is generated for IDLE or BUSY transfers to undefined
// locations, but a two cycle ERROR response is generated if a non-sequential
// or sequential transfer is attempted.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_HRESPSeq
  if (HRESETn == 1'b0)
    HRESP   <= `RSP_OKAY;
  else
    if (iHREADYOut == 1'b1)
      HRESP <= NextHRESP;
end // p_HRESPSeq

// For the two cycle error response, HREADY is set LOW during the first cycle
// and HIGH during the second cycle.
assign NextHREADY       = (iHREADYOut == 1'b0) ?
                          1'b1 : (((iHSELDefault == 1'b1) &
                          (HTRANS == `TRN_NONSEQ | HTRANS == `TRN_SEQ)) ?
                          1'b0 : 1'b1);

// -----------------------------------------------------------------------------
// Sequential logic for HREADYOut generation
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_HREADYSeq
  if (HRESETn == 1'b0)
    iHREADYOut <= 1'b1;
  else
    iHREADYOut <= NextHREADY;
end // p_HREADYSeq

// -----------------------------------------------------------------------------
// Assign internal copy of signals to output ports
// -----------------------------------------------------------------------------
assign HSELLOGICMODULE  = iHSELLOGICMODULE;
assign HSELAHBAPB       = iHSELAHBAPB;
assign HSELSSRAM        = iHSELSSRAM;
assign HSELDefault      = iHSELDefault;
assign HREADYOut        = iHREADYOut;

endmodule
// --================================== End ==================================--
