//////////////////////////////////////////////////////////////////////72
// Project Name: ARM-based platform
// File Name   : AMBA_declare.v
// Description : Parameters and definations for ARM-based platform.
//               
//               AMBA 2.0 compliance.
// Dependency  : 
// Author      : Kun-Bin Lee
// Revision History:
// Date        : 2001.5.5
// Create Data : 2001.5.5
// File Version: 
// Head Version: 
////////////////////////////////////////////////////////////////////////

// HTRANS transfer type encoding
`define AHB_IDLE   2'b00
`define AHB_BUSY   2'b01
`define AHB_NONSEQ 2'b10
`define AHB_SEQ    2'b11

// HSIZE transfer type encoding 
`define AHB_HSIZE_8   3'b000
`define AHB_HSIZE_16  3'b001
`define AHB_HSIZE_32  3'b010

// HRESP transfer response encoding
`define AHB_RSP_OKAY  2'b00
`define AHB_RSP_ERROR 2'b01
`define AHB_RSP_RETRY 2'b10
`define AHB_RSP_SPLIT 2'b11

// HBURST transfer type encoding
`define HBURST_SINGLE 3'b000
`define HBURST_INCR   3'b001
`define HBURST_WRAP4  3'b010
`define HBURST_INCR4  3'b011
`define HBURST_WRAP8  3'b100
`define HBURST_INCR8  3'b101
`define HBURST_WRAP16 3'b110
`define HBURST_INCR16 3'b111

// State encoding for the Locked Transfer state machine
`define LT_NORMAL    2'b00
`define LT_LOCKED    2'b01
`define LT_LAST_LOCK 2'b10
`define LT_SPLIT     2'b11

//--------------------------------------------------------------------
// The following parameters depends on system's requirement
//--------------------------------------------------------------------
`define AHB_DATA_WIDTH 32 //AHB data bus width
`define AHB_ADDR_WIDTH 32 //AHB addr bus width

`define NO_MASK  4'b0000 //No byte is masked
`define LSB_16   4'b0011 //LSB 16 bits are masked
`define MSB_16   4'b1100 //MSB 16 bits are masked
`define BYTE_3   4'b0111 //LSB 24~31 bits are accessed
`define BYTE_2   4'b1011 //LSB 16~23 bits are accessed
`define BYTE_1   4'b1101 //LSB 8~15  bits are accessed
`define BYTE_0   4'b1110 //LSB 0~7   bits are accessed
`define MASK_ALL 4'b1111 //mask all bytes

`define BYTE_NUM 4

//--------------------------------------------------------------------
// The following parameters are for MEM_CSR
//--------------------------------------------------------------------
`define MEM_BANK_NUM 8    //number of memory register banks in MEM_CSR
`define MEM_CSR_ADDR_W 3  //MEM CSR addr bus width
`define MEM_CSR_DATA_W 32 //MEM CSR data bus width
`define MEM_CSR_BYTE `MEM_CSR_DATA_W >> 3 //number of bytes in CSR

`define WAIT_ST_WIDTH 5  //bit width for wait state
`define WAIT_ST_1 12:8   //read access time, or
                         // initial access time for burst ROM
`define WAIT_ST_2 4:0    //write access time, or
                         // burst access time for burst ROM


//--------------------------------------------------------------------
// The following parameters are for DMA_CSR
//--------------------------------------------------------------------
`define DMA_REG_NUM 8    //number of 32-bit register in DMA_CSR
//`define DMA_CSR_ADDR_W (`DMA_BLOCK_SIZE * (`DMA_CH_NUM+1) ) >> 3
//Expired equation

`define DMA_CSR_ADDR_W 3
  //DMA CSR addr bus width
  // 2 * (channel number + DMA engine) Byte

`define DMA_CSR_DATA_W 32 //MEM CSR data bus width
`define DMA_CSR_BYTE `DMA_CSR_DATA_W >> 3 //number of bytes in CSR

//--------------------------------------------------------------------
// The following parameters are for memory banks
//--------------------------------------------------------------------

`define MEM_0_ADDR_W 32 // addres bus for MEM 0, 64MB maximum
`define MEM_0_DATA_W 32 // data bus width for MEM 0
`define MEM_0_BYTE `MEM_0_DATA_W >> 3 //num of bytes in MEM 0 data bus

`define MEM_1_ADDR_W 16 // addres bus for MEM 1, 64MB maximum
`define MEM_1_DATA_W 32 // data bus width for MEM 1
`define MEM_1_BYTE `MEM_1_DATA_W >> 3 //num of bytes in MEM 1 data bus

`define MEM_2_ADDR_W 16 // addres bus for MEM 2, 64MB maximum
`define MEM_2_DATA_W 32 // data bus width for MEM 2
`define MEM_2_BYTE `MEM_2_DATA_W >> 3 //num of bytes in MEM 2 data bus

`define MEM_3_ADDR_W 16 // addres bus for MEM 3, 64MB maximum
`define MEM_3_DATA_W 32 // data bus width for MEM 3
`define MEM_3_BYTE `MEM_3_DATA_W >> 3 //num of bytes in MEM 3 data bus

`define MEM_4_ADDR_W 16 // addres bus for MEM 4, 64MB maximum
`define MEM_4_DATA_W 32 // data bus width for MEM 4
`define MEM_4_BYTE `MEM_4_DATA_W >> 3 //num of bytes in MEM 4 data bus

`define MEM_5_ADDR_W 16 // addres bus for MEM 5, 64MB maximum
`define MEM_5_DATA_W 32 // data bus width for MEM 5
`define MEM_5_BYTE `MEM_5_DATA_W >> 3 //num of bytes in MEM 5 data bus

`define MEM_6_ADDR_W 16 // addres bus for MEM 6, 64MB maximum
`define MEM_6_DATA_W 32 // data bus width for MEM 6
`define MEM_6_BYTE `MEM_6_DATA_W >> 3 //num of bytes in MEM 6 data bus

`define MEM_7_ADDR_W 16 // addres bus for MEM 7, 64MB maximum
`define MEM_7_DATA_W 32 // data bus width for MEM 7
`define MEM_7_BYTE `MEM_7_DATA_W >> 3 //num of bytes in MEM 7 data bus

`define BANK_ADDR_INDEX 28:26 //bank selection for eight banks, 64MB each
`define MEM_ADDR_INDEX 25:0   //64MB addressable spacing used in each
                              //bank of memory



//--------------------------------------------------------------------
// The following parameters are for wait states
//--------------------------------------------------------------------

`define WAIT_CTR 5 // bit size for wait counter

`define RSP_STATE_LEN 3 //for AHB response FSM state counter


//--------------------------------------------------------------------
// The following parameters are for memory used to store test vectors
//--------------------------------------------------------------------
`define TEST_MEM_ADDR_W 19 // addres bus for test vector memory, 
`define TEST_MEM_DATA_W 60 // data bus for test vector memory


//--------------------------------------------------------------------
// The following parameters are for MuxS2M.v
//--------------------------------------------------------------------
`define AHB_SLAVE_NUM 3 //number of AHB slave modules