`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Péntek Róbert Gergő
// 
// Create Date:    14:33:56 05/21/2020 
// Design Name: 
// Module Name:    spi_master5 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spi_master5(
	input i_PRESETn,
	input i_PCLK,
	input i_SPI_CLK,
	
	input i_WR0, 	//CONFIG_SPI
	input i_WR1,	//TX_SPI
	input i_WR2,	//RX_SPI
	input i_WR3,	//CMD_SPI
	
	input i_DR0,	//STATE_SPI
	input i_DR1,	//RX_SPI
	input i_DR2,	//Optional
	input i_DR3,	//Optional
	
//APB BUSZ adatcsatornák
	input [7:0] i_PWDATA,
	output[7:0] o_PRDATA,

//SPI_MASTER
	input 		MISO,
	output 	 	MOSI,
	output wire SCK,
	
	output reg SS0,
	output reg SS1,
	output reg SS2,
	output reg SS3
	);

	reg [7:0] PRDATA;
	assign o_PRDATA=PRDATA;
	
	
//SPI_REGISTERS--------------------------------------------	 
	 
	reg[7:0] CONFIG_REG;
	reg[7:0] CMD_REG;
	reg[7:0] TX_REG;
	reg[7:0] RX_REG;
	reg[7:0] STATE_REG;

//SPI_MASTER
	reg SHIFT_IN;
	reg[7:0] SHIFT_REG;

// Allapotgep
	reg[1:0] STATE;
	reg[4:0] SCK_CNT;
	
	
//ORAJEL generator
	reg [3:0] counter;
	reg [3:0] divider;
	reg SCK_ENABLE;
	reg SPI_CLK;
	reg o_SCK;
	wire i_SCK;
	
	assign SCK=o_SCK;
	
// P/N EDGE 
	reg	d_ffp;
	reg	d_ffn;
	wire	P_EDGE;
	wire	N_EDGE;
	
	

//RESET----------------------------------------------------------------
	
	always @(posedge i_PCLK)
		begin
			if(i_PRESETn==0)
				begin
					CONFIG_REG<=8'b00000000;
					CMD_REG<=8'b00000000;
					TX_REG<=8'b00000000;
					RX_REG<=8'bZ;
					PRDATA<=8'bZ;
					SHIFT_REG<=8'bZ;
					SHIFT_IN<=1'bZ;
					STATE_REG<=8'b00000010;
					SCK_ENABLE<=1'b0;
					SCK_CNT<=5'b0;
					SPI_CLK<=1'b0;
					o_SCK<=1'b0;
					STATE<=2'b00;
					SS0<=1;
					SS1<=1;
					SS2<=1;
					SS3<=1;
				end
		end
//APB busz változóinak kezelése-----------------------------
	
	always@(posedge i_PCLK)
		begin
				case({i_WR0,i_WR1,i_WR2,i_WR3,i_DR0,i_DR1,i_DR2,i_DR3})
				8'b10000000: CONFIG_REG	<= i_PWDATA;
				8'b01000000: SHIFT_REG	<= i_PWDATA;
				8'b00100000: RX_REG		<= i_PWDATA;
				8'b00010000: CMD_REG		<= i_PWDATA;
				8'b00001000: PRDATA 	<= STATE_REG;
				8'b00000100: PRDATA 	<= RX_REG;
				8'b00000010: PRDATA 	<= TX_REG;
				8'b00000001: PRDATA 	<= CMD_REG;
				endcase
		end
//SPI_CLK generátor-----------------------------------------

always @(posedge i_PCLK)
		begin
			if(SCK_ENABLE==1)
				begin
					if(counter==divider)
						begin
						counter<=4'b0000;
						SPI_CLK<= ~SPI_CLK;
						end
						
					else
						begin
						counter<=counter+1'b1;
						end
			end
		
		end
		
//  P/N EDGE generátor--------------------------------------

always @(posedge i_PCLK)
		begin
			if(SCK_ENABLE==1)
				begin
					if(i_PRESETn==0)
						begin
						d_ffp<=1'b0;
						end
					if (SPI_CLK==1)
						begin
						d_ffp<=1'b1;
						end
					else
						begin
						d_ffp<=1'b0;
						end
				end
		end
	
assign P_EDGE=SCK_ENABLE? (~d_ffp & SPI_CLK): 1'bZ; // Positive edge
	
always @(posedge i_PCLK)
		begin
			if(SCK_ENABLE==1)
				begin
					if(i_PRESETn==0)
						begin
						d_ffn<=1'b0;
						end
					if (SPI_CLK==0)
						begin
						d_ffn<=1'b1;
						end
					else
						begin
						d_ffn<=1'b0;
						end
				end
		end
	
assign N_EDGE=SCK_ENABLE? (~d_ffn & ~SPI_CLK): 1'bZ; // Negativ edge
	
// SCK generátor-------------------------------------------

always @(posedge i_PCLK)
		begin
		if(SCK_ENABLE==1)
			begin
					if(P_EDGE)
						begin
						o_SCK<= 1'b1;
						end
					if(N_EDGE)
						begin
						o_SCK<= 1'b0;
						end
			end
		end




		
//Allapotgep----------------------------------------------		
always@(posedge i_PCLK)
		begin
		//IDLE vagy transfer után
			if(STATE==2'b00 &&CMD_REG[1]==0)
				begin
				RX_REG<=SHIFT_REG;
				STATE_REG<=8'b00000010;
				end
			
		//BUSY state
			if(STATE==2'b00 && CMD_REG[1]==1)
				begin
					STATE_REG<=8'b00000000;
					SPI_CLK<=CONFIG_REG[5];
					//#4
					STATE<=2'b01;
					end
		// CONFIG		
			if(STATE==2'b01)
				begin
					CMD_REG[1]<=1'b0;
					counter<= 4'b0000;
					SCK_CNT<= 4'b0000;
					
						case (CONFIG_REG[3:2])
								2'b00: SS0<=0;
								2'b01: SS1<=0;
								2'b10: SS2<=0;
								2'b11: SS3<=0;
						endcase
						
						case(CONFIG_REG[1:0])
						2'b00: divider<=4'b0001;
						2'b01: divider<=4'b0011;
						2'b10: divider<=4'b0111;
						2'b11: divider<=4'b1111;
						endcase
						
					STATE<=2'b10;
				end
			//TRANSFER
				if(STATE==2'b10)
					begin
					SCK_ENABLE<=1'b1;
					SHIFT_IN<=MISO;
					
					if(SCK_CNT<16)
						begin
						SCK_ENABLE<=1'b1;
						end
					else
						begin
						SCK_ENABLE<=1'b0;
						STATE<=2'b11;
						end
					end
			//TRANSFER_END
				if (STATE==2'b11)
					begin
					SCK_CNT<= 4'b0000;
					SS0<=1;
					SS1<=1;
					SS2<=1;
					SS3<=1;
					
					STATE<=2'b00;
					end	
		end
		
		
		

//SPI átvitel

assign MOSI=(({SS0,SS1,SS2,SS3})!=4'b1111)? SHIFT_REG[7] : 1'bZ;

always@(posedge i_PCLK)
	begin
		if(CONFIG_REG[5:4]==2'b00)
			begin
				if(P_EDGE)
					begin
						SHIFT_IN<=MISO;
						SCK_CNT<=SCK_CNT+1'b1;
					end
				if(N_EDGE)
					begin
						SHIFT_REG <= SHIFT_REG << 1;
						SHIFT_REG[0]<=SHIFT_IN;
						SCK_CNT<=SCK_CNT+1'b1;
					end
			end			
			
				
			
		if(CONFIG_REG[5:4]==2'b01)
			begin
				if(P_EDGE)
					begin
						SHIFT_REG <= SHIFT_REG << 1;
						SHIFT_REG[0]<=SHIFT_IN;
						SCK_CNT<=SCK_CNT+1'b1;
					end
				if(N_EDGE)
					begin
						SHIFT_IN<=MISO;
						SCK_CNT<=SCK_CNT+1'b1;
					end
			end
			
			
			

		if(CONFIG_REG[5:4]==2'b10)
			begin
				if(P_EDGE)
					begin
						SHIFT_REG <= SHIFT_REG << 1;
						SHIFT_REG[0]<=SHIFT_IN;
						SCK_CNT<=SCK_CNT+1'b1;
					end
				if(N_EDGE)
					begin
						SHIFT_IN<=MISO;
						SCK_CNT<=SCK_CNT+1'b1;
					end
			end
			
			
			
		if(CONFIG_REG[5:4]==2'b11)
			begin
				if(P_EDGE)
					begin
						SHIFT_IN<=MISO;
						SCK_CNT<=SCK_CNT+1'b1;
					end
				if(N_EDGE)
					begin
						SHIFT_REG <= SHIFT_REG << 1;
						SHIFT_REG[0]<=SHIFT_IN;
						SCK_CNT<=SCK_CNT+1'b1;
					end
			end
end
				
	

endmodule

