module AHB_Testsys;

reg	HCLK;
reg		HRESETn;
wire	[1:0]	iHTRANS;
wire		iHWRITE;
wire	[1:0]	iHSIZE;
wire		inPBUTT;
wire	[7:0]	iSW;
wire	[3:0]	iHDRID;
wire	[31:0]	iHADDR;
wire		iHREADY_s2m;
wire	[31:0]	iHWDATA;
wire	[31:0]	iHRDATA;
wire	[1:0]	iHRESP;
wire		iHBUSREQ;
wire		iHLOCK;

wire		inLMINT;
wire	[8:0]	iLED;
wire	[18:0]	iCTRLCLK1;
wire	[18:0]	iCTRLCLK2;      

wire		iSCLK;
wire	[3:0]	iSnWBYTE;
wire		iSnOE;	
wire		iSnCE;
wire		iSADVnLD;
wire		iSnWR;
wire		iSnCKE;
wire		iSMODE;
wire	[31:0]	iSWDATA;
wire	[31:0]	iSRDATA;
wire	[17:0]	iSADDR;



assign inPBUTT = 1'b1;
assign iSW = 8'h0;
assign iHDRID = 4'b1110;

AHBAHBTop u_lm_ahbapbtop(
// Inputs
                  // AHB interface
                  .HCLK(HCLK),
                  .HRESETn(HRESETn),
                  .HTRANS(iHTRANS),
                  .HWRITE(iHWRITE),
                  .HSIZE(iHSIZE),
                  .nPBUTT(inPBUTT),
                  .SW(iSW),
                  .HDRID(iHDRID),
                  .HADDR(iHADDR),
		  .HWDATA(iHWDATA),
// Outputs
		  .HREADYout(iHREADY_s2m),
		  .HRDATA(iHRDATA),
                  .HRESP(iHRESP),
//                  .HBUSREQ(iHBUSREQ),
                  .HLOCK(iHLOCK),
                  // APB I/O (SLAVE 1)
                  .nLMINT(inLMINT),
                  .LED(iLED),
                  .CTRLCLK1(iCTRLCLK1),
                  .CTRLCLK2(iCTRLCLK2),
                  // ZBT RAM (SLAVE 2)
                  .SCLK(iSCLK),
                  .SnWBYTE(iSnWBYTE),
                  .SnOE(iSnOE),
                  .SnCE(iSnCE),
                  .SADVnLD(iSADVnLD),
                  .SnWR(iSnWR),
                  .SnCKE(iSnCKE),
                  .SMODE(iSMODE),
		  .SWDATA(iSWDATA),
		  .SRDATA(iSRDATA),
                  .SADDR(iSADDR)
                 );

//---- SRAM Model: 
SRAM_8X4X4096 u_zbtssram(
        .SCLK(iSCLK),
        .SnWBYTE(iSnWBYTE),
        .SnCE(iSnCE),
        .SnWR(iSnWR),
        .SnOE(iSnOE),
        .SADDR(iSADDR),
        .SWDATA(iSWDATA),
        .SRDATA(iSRDATA)  	
);


// Single master, no HGRANT signal, and no arbiter
//---- AHB Hostcommander master
AHB_HC_master u_hcmaster(
                  .HCLK(HCLK),
                  .HRESETn(HRESETn),
// Outputs
                  .HTRANS(iHTRANS),
                  .HWRITE(iHWRITE),
                  .HSIZE(iHSIZE),
                  .HADDR(iHADDR),
                  .HWDATA(iHWDATA),
// Inputs
                  .HREADYin(iHREADY_s2m),
                  .HRDATA(iHRDATA),
                  .HRESP(iHRESP),
                  .HBUSREQ(iHBUSREQ),
                  .HLOCK(iHLOCK)     
);
/*
AHB_Dummy_master u_dummymaster(

);

AHB_arbiter
*/

parameter       cycle=10;
always #(cycle/2)
        HCLK = ~HCLK;

initial 
begin
    $recordfile("LM_AHBAPB_test.trn");
    $recordvars();
	HCLK = 1'b1;
	#2;
	#cycle	HRESETn = 1'b0;
	#(cycle*4)  HRESETn = 1'b1;
	#(cycle*20)

$finish;

end

endmodule
