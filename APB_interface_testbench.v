`timescale 10ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Péntek Róbert Gergő
//
// Create Date:   15:32:54 05/24/2020
// Design Name:   APB_interface_2
// Module Name:   C:/PROG/xilinx/APB_interface/APB_interface2_testbench.v
// Project Name:  APB_interface
// Target Device:  
// Tool versions:  
// Description: 
//
// 
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module APB_interface2_testbench;

	// Inputs
	reg i_PRESETn;
	reg i_PCLK;
	reg i_PSEL0;
	reg i_PENABLE;
	reg i_PWRITE;
	reg [15:0] i_PADDR;
	reg [7:0] i_PWDATA;
	reg [7:0] i_PRDATA;
	reg [9:0] i_BASE_ADDR;

	// Outputs
	wire o_WR0;
	wire o_WR1;
	wire o_WR2;
	wire o_WR3;
	wire o_DR0;
	wire o_DR1;
	wire o_DR2;
	wire o_DR3;
	wire PREADY;
	wire [7:0] o_PWDATA;
	wire [7:0] o_PRDATA;

	// Instantiate the Unit Under Test (UUT)
	APB_interface_2 uut (
		.i_PRESETn(i_PRESETn), 
		.i_PCLK(i_PCLK), 
		.i_PSEL0(i_PSEL0), 
		.i_PENABLE(i_PENABLE), 
		.i_PWRITE(i_PWRITE), 
		.i_PADDR(i_PADDR), 
		.i_PWDATA(i_PWDATA), 
		.i_PRDATA(i_PRDATA), 
		.i_BASE_ADDR(i_BASE_ADDR), 
		.o_WR0(o_WR0), 
		.o_WR1(o_WR1), 
		.o_WR2(o_WR2), 
		.o_WR3(o_WR3), 
		.o_DR0(o_DR0), 
		.o_DR1(o_DR1), 
		.o_DR2(o_DR2), 
		.o_DR3(o_DR3),
		.PREADY(PREADY),
		.o_PWDATA(o_PWDATA), 
		.o_PRDATA(o_PRDATA)
	);
	//READ parameters
	localparam STATUS	= 4'b0000;
	localparam RX		= 4'b0001;
	
	//Write parameters
	localparam MODE00	= 2'b00;
	localparam MODE01	= 2'b01;
	localparam MODE10	= 2'b10;
	localparam MODE11	= 2'b11;
	
	localparam SLAVE0	= 2'b00;
	localparam SLAVE1	= 2'b01;
	localparam SLAVE2	= 2'b10;
	localparam SLAVE3	= 2'b11;
	
	localparam SCK8	= 2'b00; //8MHZ Ha PCLK 16MHZ!!!
	localparam SCK4	= 2'b01; //4MHZ
	localparam SCK2	= 2'b10; //2MHZ
	localparam SCK1	= 2'b11; //1MHZ
	
	task APB_READ(input RD);
		begin
			case(RD)
			4'b0000: i_PADDR=16'b0000000001000000;
			4'b0001: i_PADDR=16'b0000000001000100;
			endcase
			i_PWRITE=0;i_PSEL0=1;
			#6.25
			i_PENABLE=1;
			#6.25
			i_PSEL0=0; i_PENABLE=0;
			
		end
	endtask
	
	task APB_WRITE(input[1:0] MODE, SLAVE,SCK, input [7:0] DATA);
		begin
		///CONFIG write-------------------------------------------------------------------------	

			i_PWDATA=({2'b00, MODE, SLAVE, SCK});
			i_PADDR=16'b0000000001000000; i_PWRITE=1; i_PSEL0=1; // CONFIG_REG irása
			#6.25
			i_PENABLE=1;
			#6.25
			i_PSEL0=0; i_PENABLE=0;i_PWRITE=0;
		///TX write-----------------------------------------------------------------------------
			#6.25
			i_PADDR=16'b0000000001000100;i_PWRITE=1;i_PSEL0=1;i_PWDATA=DATA;// TX data
			#6.25
			i_PENABLE=1;
			#6.25
			i_PSEL0=0; i_PENABLE=0;i_PWRITE=0;
		///CMD write-----------------------------------------------------------------------------				
			#6.25
			i_PADDR=16'b0000000001001100;i_PWRITE=1;i_PSEL0=1;i_PWDATA=8'b00000010; //CMD REG
			#6.25
			i_PENABLE=1;
			#6.25
			i_PSEL0=0; i_PENABLE=0;i_PWRITE=0;
		end
	endtask
	
	
	initial begin
	i_PCLK=1'b0;
	forever #3.125 i_PCLK=~i_PCLK;
	end

	initial begin
		// Initialize Inputs
		i_PRESETn = 0;
		i_PCLK = 0;
		i_PSEL0 = 0;
		i_PENABLE = 0;
		i_PWRITE = 0;
		i_PADDR = 0;
		i_PWDATA = 0;
		i_PRDATA = 0;
		i_BASE_ADDR = 10'b0000000001;

		// Wait 100 ns for global reset to finish
		
		#3.125
		#6.25
		i_PRESETn = 1;
		#25
		APB_WRITE(MODE00,SLAVE0,SCK4,8'b01010101);
		#450
		APB_READ(RX);
		#50
		APB_READ(STATUS);
		#50
		APB_WRITE(MODE01,SLAVE1,SCK8,8'b01010101);
		#250
		APB_READ(RX);
		#50
		APB_WRITE(MODE10,SLAVE2,SCK8,8'b01010101);
		#250
		APB_READ(RX);
		#50
		APB_WRITE(MODE11,SLAVE3,SCK8,8'b01010101);
		#250
		APB_READ(RX);
		#50
			
		$stop;

        
		

	end
      
endmodule

