

module AHB_HC_master(
                  HCLK,
                  HRESETn,
// Outputs
                  HTRANS,
                  HWRITE,
                  HSIZE,
                  HADDR,
                  HWDATA,
// Inputs
                  HREADYin,
                  HRDATA,
                  HRESP,
                  HBUSREQ,
                  HLOCK
);
input		HCLK;
input		HRESETn;
output	[1:0]	HTRANS;
output		HWRITE;
output	[1:0]	HSIZE;
output	[31:0]	HADDR;
output	[31:0]	HWDATA;
output		HBUSREQ;
output		HLOCK;

//input
input		HREADYin;
input	[1:0]	HRESP;
input	[31:0]	HRDATA;


// reg output
reg  [1:0]   HTRANS;
reg          HWRITE;
reg  [1:0]   HSIZE;
reg  [31:0]  HADDR;
reg  [31:0]  HWDATA; 
reg	     HBUSREQ;
reg	     HLOCK;

reg  [31:0]  RDATA;
wire [31:0]  RDATA_tmp;

initial
begin
	// time 0
	HWRITE = 1'b0;   
	HTRANS = `AHB_IDLE;
	HSIZE = `AHB_HSIZE_32;
	HADDR = 32'hC000_0000;
	HWDATA = 32'h0000_0000;
	HBUSREQ = 1'b0;
	HLOCK = 1'b0;
	
	@(negedge HRESETn)
	if(!HRESETn)
	begin
		#60;
	end

	// Non-sequential read @0x
	@(posedge HCLK)
	begin
	    #2;
	    if((HREADYin==1'b1)&&(HRESP==`AHB_RSP_OKAY))
	    begin
			HWRITE = 1'b0;
			HTRANS = `AHB_NONSEQ;
	        HSIZE = `AHB_HSIZE_32;
			HADDR = 32'hC200_0000;	// NS Read @ 0x0200_0000
	        HWDATA = 32'h0000_0000;
			HBUSREQ = 1'b1;
			HLOCK = 1'b0;
	    end
	end

	@(posedge HCLK) 
	begin
            #2;
	    if((HREADYin==1'b1)&&(HRESP==`AHB_RSP_OKAY))
	    begin
			HWRITE = 1'b0;
			HTRANS = `AHB_NONSEQ;
	        HSIZE = `AHB_HSIZE_32;
			HADDR = 32'hC200_0010;	// NS Read @ 0xC200_0000
			HWDATA = 32'h0000_0000;
			HBUSREQ = 1'b1;
			HLOCK = 1'b0;
	    end
	end
	
	// Non-sequential write @0x0200_0000
	@(posedge HCLK) 
	begin
	    #2;
	    if((HREADYin==1'b1)&&(HRESP==`AHB_RSP_OKAY))
	    begin
			HWRITE = 1'b1;
			HTRANS = `AHB_NONSEQ;
	        HSIZE = `AHB_HSIZE_32;
			HADDR = 32'hC200_0000;	// NS Write @ 0xC200_0000
			HWDATA = 32'h0000_0000;
			HBUSREQ = 1'b1;
			HLOCK = 1'b0;
	    end
	end
	@(posedge HCLK) 
	begin
	    #2;
	    if((HREADYin==1'b1)&&(HRESP==`AHB_RSP_OKAY))
	    begin
			HWRITE = 1'b0;	//This read is not allowed
			HTRANS = `AHB_NONSEQ;
	        HSIZE = `AHB_HSIZE_32;
			HADDR = 32'hC200_0010;	// NS Write @ 0xC200_0000
			HWDATA = 32'h0000_1234;
			HBUSREQ = 1'b1;
			HLOCK = 1'b0;
	    end
	end

	@(posedge HCLK)

	// Non-sequential read @0x0200_0000
	@(posedge HCLK) 
	begin
	    #2;
	    if((HREADYin==1'b1)&&(HRESP==`AHB_RSP_OKAY))
	    begin
			HWRITE = 1'b0;
			HTRANS = `AHB_NONSEQ;
	        HSIZE = `AHB_HSIZE_32;
			HADDR = 32'hC200_0000;	// NS Write @ 0xC200_0000
			HWDATA = 32'h0000_0000;
			HBUSREQ = 1'b1;
			HLOCK = 1'b0;
	    end
	end
	@(posedge HCLK) 
	begin
	    #2;
	    if((HREADYin==1'b1)&&(HRESP==`AHB_RSP_OKAY))
	    begin
			HWRITE = 1'b0;
			HTRANS = `AHB_NONSEQ;
	        HSIZE = `AHB_HSIZE_32;
			HADDR = 32'hC200_0010;	// NS Write @ 0xC200_0000
			HWDATA = 32'h0000_0000;
			HBUSREQ = 1'b1;
			HLOCK = 1'b0;
	    end
	end
end

assign RDATA_tmp = RDATA;

always @(posedge HCLK or negedge HRESETn)
begin
	if(!HRESETn)
	begin
	    RDATA<=32'h0;
	end
	else
	begin
	    if((HREADYin==1'b1)&&(HRESP==`AHB_RSP_OKAY)) 
	    begin
	        RDATA<=HRDATA;
	    end
	    else
	    begin
	        RDATA<=RDATA_tmp;
	    end
	end
end

endmodule
