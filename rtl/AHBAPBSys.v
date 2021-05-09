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
//           Connects APB peripheral to the AHB-APB bridge.
//
// --=========================================================================--

`timescale 1ns/1ps

// -----------------------------------------------------------------------------

module AHBAPBSys (
// Inputs
                  HCLK,
                  HRESETn,
                  HTRANS,
                  HWRITE,
                  HSELAHBAPB,
                  HREADYIn,
                  nPBUTT,
                  SW,
                  HWDATA,
                  HADDR,
// Outputs
                  HREADYOut,
                  HRESP,
                  nLMINT,
                  CTRLCLK1,
                  CTRLCLK2,
                  LED,
                  HRDATA
                 );

// Inputs
input         HCLK;       // system bus clock
input         HRESETn;    // reset input (active low)
input   [1:0] HTRANS;     // AHB transfer type
input         HWRITE;     // AHB hwrite
input         HSELAHBAPB; // AHB peripheral select
input         HREADYIn;   // AHB ready input
input         nPBUTT;     // input that will be latched for an
                          // interrupt example
input   [7:0] SW;         // switches
input  [31:0] HWDATA;     // AHB write data bus
input  [31:0] HADDR;      // AHB address bus

// Outputs
output        HREADYOut;  // AHB ready output to S->M mux
output  [1:0] HRESP;      // AHB response
output        nLMINT;     // LM peripheral interrupt request
output [18:0] CTRLCLK1;   // sets frequency of CLK1
output [18:0] CTRLCLK2;   // sets frequency of CLK2
output  [8:0] LED;        // LED control
output [31:0] HRDATA;     // AHB read data bus

// Inputs
wire          HCLK;       // system bus clock
wire          HRESETn;    // reset input (active low)
wire    [1:0] HTRANS;     // AHB transfer type
wire          HWRITE;     // AHB hwrite
wire          HSELAHBAPB; // AHB peripheral select
wire          HREADYIn;   // AHB ready input
wire          nPBUTT;     // input that will be latched for an
                          // interrupt example
wire    [7:0] SW;         // switches
wire   [31:0] HWDATA;     // AHB write data bus
wire   [31:0] HADDR;      // AHB address bus

// Outputs
wire          HREADYOut;  // AHB ready output to S->M mux
wire    [1:0] HRESP;      // AHB response
wire          nLMINT;     // LM peripheral interrupt request
wire   [18:0] CTRLCLK1;   // sets frequency of CLK1
wire   [18:0] CTRLCLK2;   // sets frequency of CLK2
wire    [8:0] LED;        // LED control
wire   [31:0] HRDATA;     // AHB read data bus

// -----------------------------------------------------------------------------
//
//                                  AHBAPBSys
//                                  =========
//
// -----------------------------------------------------------------------------
//
// Overview
// ========
// APB system.glues together APB peripheral and connects them to the AHB-APB
// bridge.
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Constant declarations
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Wire declarations
// -----------------------------------------------------------------------------
wire [31:0] PA;
// Peripheral address bus

wire        PWRITE;
// Peripheral bus Write

wire        PENABLE;
// Peripheral Enable Signal

wire [31:0] PWDATA;
// APB write data

wire [31:0] PRDATA;
// APB read data

wire        PSELREGS;
// Peripheral select - register peripheral

wire        PSELINTC;
// Peripheral select - interrupt controller

wire  [7:4] INTSRC;
// vector used to concatenate interrupt sources

wire [31:0] RegPRData;
// read data from register peripheral

wire [31:0] RegPRDataMux;
// read data presented to mux

wire  [7:0] IntcntPRData;
// read data from interrupt controller

wire  [7:0] IntcntPRDataMux;
// read data presented to mux

wire        REGSINT;
// interrupt from register peripheral

// -----------------------------------------------------------------------------
// Register declarations
// -----------------------------------------------------------------------------

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
// Instantiation of AHB2APB
// -----------------------------------------------------------------------------
AHB2APB uAHB2APB                       (
                     .HCLK             (HCLK),
                     .HRESETn          (HRESETn),
                     .HTRANS           (HTRANS),
                     .HWRITE           (HWRITE),
                     .HSELAHBAPB       (HSELAHBAPB),
                     .HREADYIn         (HREADYIn),
                     .PRDATA           (PRDATA),
                     .HWDATA           (HWDATA),
                     .HADDR            (HADDR),
                     .PENABLE          (PENABLE),
                     .HREADYOut        (HREADYOut),
                     .HRESP            (HRESP),
                     .PWRITE           (PWRITE),
                     .PSELREGS         (PSELREGS),
                     .PSELINTC         (PSELINTC),
                     .PWDATA           (PWDATA),
                     .HRDATA           (HRDATA),
                     .PADDR            (PA)
                    );

// -----------------------------------------------------------------------------
// Instantiation of APBRegs
// -----------------------------------------------------------------------------
APBRegs uAPBRegs                       (
                     .PCLK             (HCLK),
                     .nRESET           (HRESETn),
                     .PENABLE          (PENABLE),
                     .PSEL             (PSELREGS),
                     .PWRITE           (PWRITE),
                     .nPBUTT           (nPBUTT),
                     .SW               (SW),
                     .PWDATA           (PWDATA[31 : 0]),
                     .PA               (PA[4 : 2]),
                     .CTRLCLK1         (CTRLCLK1),
                     .CTRLCLK2         (CTRLCLK2),
                     .REGSINT          (REGSINT),
                     .LED              (LED),
                     .PRDATA           (RegPRData)
                    );

// -----------------------------------------------------------------------------
// Instantiation of APBIntcon
// -----------------------------------------------------------------------------
APBIntcon uAPBIntcon (
                     .PCLK             (HCLK),
                     .nRESET           (HRESETn),
                     .PENABLE          (PENABLE),
                     .PSEL             (PSELINTC),
                     .PWRITE           (PWRITE),
                     .INTSRC           (INTSRC),
                     .PWDATA           (PWDATA[7 : 0]),
                     .PADDR            (PA[7 : 2]),
                     .nLMINT           (nLMINT),
                     .PRDATA           (IntcntPRData)
                    );

// -----------------------------------------------------------------------------
// MUX the read busses
// -----------------------------------------------------------------------------
assign RegPRDataMux     = (PSELREGS == 1'b1) ? RegPRData : 32'h00000000;

assign IntcntPRDataMux  = (PSELINTC == 1'b1) ? IntcntPRData : 8'b00000000;

assign PRDATA           = {24'h000000, IntcntPRDataMux[7:0]} |
                          (RegPRDataMux[31:0]);

// -----------------------------------------------------------------------------
// Concatenate interrupt sources. This example only uses one interrupt
// -----------------------------------------------------------------------------
// 7:4 interrupt sources, 3:0 are soft interrupts assigned inside controller
assign INTSRC           = ({1'b0, 1'b0, 1'b0, REGSINT});

endmodule
// --================================== End ==================================--
