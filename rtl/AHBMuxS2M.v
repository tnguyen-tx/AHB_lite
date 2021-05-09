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
//           Central multiplexor - signals from slaves to masters
//
// --=========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------

module AHBMuxS2M (
// Inputs
                  HCLK,
                  HRESETn,
                  HSELAHBAPB,
                  HSELSSRAM,
                  HREADYAHBAPB,
                  HREADYSSRAM,
                  HREADYDefault,
                  HRESPAHBAPB,
                  HRESPSSRAM,
                  HRESPDefault,
                  HREADYIn,
                  HRDATAAHBAPB,
                  HRDATASSRAM,
// Outputs
                  HREADYOut,
                  HRESP,
                  HRDATA
                  );

// Inputs
input         HCLK;          // system bus clock
input         HRESETn;       // reset input (active low)
input         HSELAHBAPB;    // AHB peripheral select - APB bridge
input         HSELSSRAM;     // AHB peripheral select - SSRAM
input         HREADYAHBAPB;  // hready from APB
input         HREADYSSRAM;   // hready from SSRAM
input         HREADYDefault; // hready from default slave (in decoder)
input   [1:0] HRESPAHBAPB;   // hresponse from APB
input   [1:0] HRESPSSRAM;    // hresponse from SSRAM
input   [1:0] HRESPDefault;  // hresponse from default slave
input         HREADYIn;      // hready in
input  [31:0] HRDATAAHBAPB;  // read data bus from APB
input  [31:0] HRDATASSRAM;   // read data bus from SSRAM

// Outputs
output        HREADYOut;     // muxed hready out
output  [1:0] HRESP;         // muxed response out
output [31:0] HRDATA;        // muxed read data bus out to master(s)

// Inputs
wire          HCLK;          // system bus clock
wire          HRESETn;       // reset input (active low)
wire          HSELAHBAPB;    // AHB peripheral select - APB bridge
wire          HSELSSRAM;     // AHB peripheral select - SSRAM
wire          HREADYAHBAPB;  // hready from APB				         
wire          HREADYSSRAM;   // hready from SSRAM
wire          HREADYDefault; // hready from default slave (in decoder)
wire    [1:0] HRESPAHBAPB;   // hresponse from APB
wire    [1:0] HRESPSSRAM;    // hresponse from SSRAM
wire    [1:0] HRESPDefault;  // hresponse from default slave
wire          HREADYIn;      // hready in
wire   [31:0] HRDATAAHBAPB;  // read data bus from APB
wire   [31:0] HRDATASSRAM;   // read data bus from SSRAM

// Outputs
wire          HREADYOut;     // muxed hready out
wire    [1:0] HRESP;         // muxed response out
wire   [31:0] HRDATA;        // muxed read data bus out to master(s)

// -----------------------------------------------------------------------------
//
//                                  AHBMuxS2M
//                                  =========
//
// -----------------------------------------------------------------------------
//
// Overview
// ========
// Central multiplexor - signals from slaves to masters
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------
wire     iHREADY;
// Internal HREADY used as HSEL register enable

// -----------------------------------------------------------------------------
// Register declarations
// -----------------------------------------------------------------------------
reg      SelAHBAPB;
// Select signal

reg      Selssram;
// Selecct SSRAM

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
// HSEL registers
// Registered HSEL outputs are needed to control the slave output multiplexors,
// as the multiplexors must be switched in the cycle after the HSEL signals
// have been driven.
// -----------------------------------------------------------------------------
always @(negedge HRESETn or posedge HCLK)
begin : p_HSELSeq
  if (HRESETn == 1'b0)
    begin
      SelAHBAPB  <= 1'b0;
      Selssram   <= 1'b0;
    end
  else
    if (HREADYIn == 1'b1)
      begin
        SelAHBAPB <= HSELAHBAPB;
        Selssram  <= HSELSSRAM;
      end
end // p_HSELSeq

// -----------------------------------------------------------------------------
// multiplexors controlling read data and responses from slaves to masters.
// -----------------------------------------------------------------------------
assign HRDATA           = (SelAHBAPB == 1'b1) ?
                          HRDATAAHBAPB : ((Selssram == 1'b1) ?
                          HRDATASSRAM  : 32'h00000000);	

assign iHREADY          = (SelAHBAPB == 1'b1) ?
                           HREADYAHBAPB : ((Selssram == 1'b1) ?
                           HREADYSSRAM  : HREADYDefault);

assign HREADYOut        = iHREADY;

assign HRESP            = (SelAHBAPB == 1'b1) ?
                           HRESPAHBAPB  : ((Selssram == 1'b1) ?
                           HRESPSSRAM   : HRESPDefault); 

endmodule

// --================================== End ==================================--
