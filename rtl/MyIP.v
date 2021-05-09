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
// File Name              : MYIP.v
// File Revision          : 0.00
//
// Release Information    : $State: $
//
// -----------------------------------------------------------------------------
// Purpose :
//           AHB MYIP reg template
//
// --=========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------

module MYIP (
// Inputs
                  HCLK,
                  HRESETn,
                  HSELMYIP,
                  HREADYIn,
                  HTRANS,
                  HSIZE,
                  HWRITE,
                  HWDATA,
                  HADDR,
// Outputs
                  HREADYOut,
                  HRESP,
                  HRDATA,
                  );

// Inputs
input         HCLK;      // system bus clock
input         HRESETn;   // reset input (active low)
input         HSELMYIP; // AHB peripheral select
input         HREADYIn;  // AHB ready input
input   [1:0] HTRANS;    // AHB transfer type
input   [1:0] HSIZE;     // AHB hsize
input         HWRITE;    // AHB hwrite
input  [31:0] HWDATA;    // AHB write data bus
input  [31:0] HADDR;     // AHB address bus

// Outputs
output        HREADYOut; // AHB ready output to S->M mux
output  [1:0] HRESP;     // AHB response
output [31:0] HRDATA;    // AHB read data bus

// Inputs
wire          HCLK;      // system bus clock
wire          HRESETn;   // reset input (active low)
wire          HSELMYIP; // AHB peripheral select
wire          HREADYIn;  // AHB ready input
wire    [1:0] HTRANS;    // AHB transfer type
wire    [1:0] HSIZE;     // AHB hsize
wire          HWRITE;    // AHB hwrite
wire   [31:0] HWDATA;    // AHB write data bus
wire   [31:0] HADDR;     // AHB address bus

// Outputs
wire          HREADYOut; // AHB ready output to S->M mux
wire    [1:0] HRESP;     // AHB response
wire   [31:0] HRDATA;    // AHB read data bus

reg	[31:0]	tmp_data;
reg	[31:0]	tmp_data_nxt;
// -----------------------------------------------------------------------------
//
//                                  AHBZBTRAM
//                                  =========
//
// -----------------------------------------------------------------------------
//
// Overview
// ========
// AHB ZBT SRAM controller
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------
`define ST_IDLE          2'b00
`define ST_READ          2'b01
`define ST_WRITE         2'b10

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
wire       Valid;
// Module is selected with valid transfer

// -----------------------------------------------------------------------------
// Register declarations
// -----------------------------------------------------------------------------
reg  [1:0] NextState;
// State machine

reg  [1:0] CurrentState;
// Current state

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
// Valid transfer detection
// The slave must only respond to a valid transfer, so this must be detected.
// Valid AHB transfers only take place when a non-sequential or sequential
// transfer is shown on HTRANS - an idle or busy transfer should be ignored.
// -----------------------------------------------------------------------------
assign Valid            = ((HSELMYIP == 1'b1) & (HREADYIn == 1'b1) &
                           ((HTRANS == `TRN_NONSEQ) | (HTRANS == `TRN_SEQ))) ?
                          1'b1 : 1'b0;

// -----------------------------------------------------------------------------
// Next state logic for APB state machine
// Generates next state from CurrentState and AHB inputs.
// -----------------------------------------------------------------------------
always @(CurrentState or Valid or HWRITE)
begin : p_NextStateComb
  case (CurrentState)

    // Idle state
    `ST_IDLE :
      if (Valid == 1'b1)
        if (HWRITE == 1'b1)
          NextState = `ST_WRITE;
        else
          NextState = `ST_READ;
      else
        NextState   = `ST_IDLE;

    // second read cycle
    `ST_READ :
      if (Valid == 1'b1)
        if (HWRITE == 1'b1)
          NextState = `ST_WRITE;
        else
          NextState = `ST_READ;
      else
        NextState   = `ST_IDLE;

    // second write cycle
    `ST_WRITE :
      if (Valid == 1'b1)
        if (HWRITE == 1'b1)
          NextState = `ST_WRITE;
        else
          NextState = `ST_READ;
      else
        NextState   = `ST_IDLE;

    // Return to idle on FSM error
    default :
       NextState    = `ST_IDLE;

  endcase
end // p_NextStateComb

// -----------------------------------------------------------------------------
// Signals controlled by statemachine
// -----------------------------------------------------------------------------
// SRAM DATA tristate control passed to top top level
// assign SDATAEN          = (CurrentState == `ST_WRITE) ? 1'b1 : 1'b0;

// Ensure that ZBT cannot drive out during a write
// assign SnOE             = (CurrentState == `ST_WRITE) ? 1'b1 : 1'b0;
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
// ZBT SRAM output drivers
// -----------------------------------------------------------------------------
//assign SWDATA           = HWDATA;

//assign SADDR            = HADDR[19:2];

//assign SCLK             = HCLK;

//assign SnWBYTE[0]       = (((HADDR[1:0] == 2'b00) &&
//                            (HSIZE[1:0] == 2'b00)) ||
//                           ((HADDR[1] == 1'b0) && (HSIZE[1:0] == 2'b01)) ||
//                           ((HSIZE[1:0] == 2'b10))) ? 1'b0 : 1'b1;

//assign SnWBYTE[1]       = (((HADDR[1:0] == 2'b01) &&
//                            (HSIZE[1:0] == 2'b00)) ||
//                           ((HADDR[1] == 1'b0) && (HSIZE[1:0] == 2'b01)) ||
//                           ((HSIZE[1:0] == 2'b10))) ? 1'b0 : 1'b1;

//assign SnWBYTE[2]      =  (((HADDR[1:0] == 2'b10) &&
//                            (HSIZE[1:0] == 2'b00)) ||
//                          ((HADDR[1] == 1'b1) && (HSIZE[1:0] == 2'b01)) ||
//                           ((HSIZE[1:0] == 2'b10))) ? 1'b0 : 1'b1;


//assign SnWBYTE[3]      = (((HADDR[1:0] == 2'b11) &&
//                           (HSIZE[1:0] == 2'b00)) ||
//                          ((HADDR[1] == 1'b1) && (HSIZE[1:0] == 2'b01)) ||
//                         ((HSIZE[1:0] == 2'b10))) ? 1'b0 : 1'b1;

//assign SnCE            = (Valid == 1'b1) ? 1'b0 : 1'b1;

//assign SnWR            = ~(HWRITE);

//assign SADVnLD         = 1'b0;

//assign SMODE           = 1'b0;

//assign SnCKE           = 1'b0;

always @(CurrentState or HWDATA or tmp_data)
begin
  case (CurrentState)
    // Idle state
    `ST_IDLE :
	tmp_data_nxt = tmp_data;
    // second read cycle
    `ST_READ :
	tmp_data_nxt = tmp_data;
    // second write cycle
    `ST_WRITE :
	tmp_data_nxt = HWDATA;
    // Return to idle on FSM error
    default :
	tmp_data_nxt = tmp_data;
  endcase
end

always @(negedge HRESETn or posedge HCLK)
begin
  if (HRESETn == 1'b0)
    tmp_data <= 32'h0;
  else
    tmp_data <= tmp_data_nxt;
end
// -----------------------------------------------------------------------------
// AHB output drivers
// -----------------------------------------------------------------------------
assign HRDATA          = tmp_data;
assign HRESP           = `RSP_OKAY;
assign HREADYOut       = 1'b1;

endmodule

// --================================== End ==================================--
