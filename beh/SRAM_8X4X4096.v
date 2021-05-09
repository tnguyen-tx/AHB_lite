module SRAM_8X4X4096(
	SCLK,
	SnWBYTE,
	SnCE,
	SnWR,
	SnOE,
	SADDR,
	SWDATA,
	SRDATA
);
input 		SCLK;
input	[3:0]	SnWBYTE;
input		SnCE;
input		SnWR;
input		SnOE;
input	[17:0]	SADDR;
input	[31:0]	SWDATA;
output	[31:0]	SRDATA;

wire	[31:0]	iSWDATA;
wire	[3:0]	SnWBE;

wire	[3:0]	iSnWBE;
wire	[17:0]	iSADDR;
reg	[3:0]	SnWBE_t;
reg	[17:0]	SADDR_t;
reg		SnWR_t;

/* SRDATA has no BYTE read control
assign SRDATA[7:0] = (SnWBYTE[0])?iSRDATA[7:0]:8'h00000000;
assign SRDATA[15:8] = (SnWBYTE[1])?iSRDATA[15:8]:8'h00000000;
assign SRDATA[23:16] = (SnWBYTE[2])?iSRDATA[23:16]:8'h00000000;
assign SRDATA[31:24] = (SnWBYTE[3])?iSRDATA[32:24]:8'h00000000;   
*/
assign iSWDATA[7:0] = (~SnWBYTE[0])?SWDATA[7:0]:8'h00;
assign iSWDATA[15:8] = (~SnWBYTE[1])?SWDATA[15:8]:8'h00; 
assign iSWDATA[23:16] = (~SnWBYTE[2])?SWDATA[23:16]:8'h00;   
assign iSWDATA[31:24] = (~SnWBYTE[3])?SWDATA[31:24]:8'h00;   

assign SnWBE[0] = SnWBYTE[0]|SnWR;
assign SnWBE[1] = SnWBYTE[1]|SnWR;
assign SnWBE[2] = SnWBYTE[2]|SnWR;
assign SnWBE[3] = SnWBYTE[3]|SnWR;

always @(posedge SCLK)
begin
    SADDR_t <= SADDR;
    SnWBE_t <= SnWBE;
    SnWR_t <= SnWR;
end

assign iSADDR = SnWR_t?SADDR:SADDR_t;
assign iSnWBE = SnWBE_t;
RA1SH u0_ra1sh(
   .Q(SRDATA[7:0]),
   .CLK(SCLK),
   .CEN(SnCE),
   .WEN(iSnWBE[0]),
   .A(iSADDR[11:0]),	//only 4K address space is supported here
   .D(iSWDATA[7:0]),
   .OEN(SnOE)
);

RA1SH u1_ra1sh(
   .Q(SRDATA[15:8]),
   .CLK(SCLK),
   .CEN(SnCE),
   .WEN(iSnWBE[1]),
   .A(iSADDR[11:0]),     //only 4K address space is supported here
   .D(iSWDATA[15:8]),
   .OEN(SnOE)
);

RA1SH u2_ra1sh(
   .Q(SRDATA[23:16]),
   .CLK(SCLK),
   .CEN(SnCE),
   .WEN(iSnWBE[2]),
   .A(iSADDR[11:0]),     //only 4K address space is supported here
   .D(iSWDATA[23:16]),
   .OEN(SnOE)
);

RA1SH u3_ra1sh(
   .Q(SRDATA[31:24]),
   .CLK(SCLK),
   .CEN(SnCE),
   .WEN(iSnWBE[3]),
   .A(iSADDR[11:0]),     //only 4K address space is supported here
   .D(iSWDATA[31:24]),
   .OEN(SnOE)
);




endmodule
