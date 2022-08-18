////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText:  2021 , Dinesh Annayya
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
// SPDX-FileContributor: Modified by Dinesh Annayya <dinesha@opencores.org>
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Standalone User validation Test bench                       ////
////                                                              ////
////  This file is part of the Riscduino cores project            ////
////                                                              ////
////  Description                                                 ////
////   This is a standalone test bench to validate the            ////
////   Digital core with Risc core executing code from TCM/SRAM.  ////
////   with icache and dcache bypass mode                         ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 16th Feb 2021, Dinesh A                             ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`default_nettype wire

`timescale 1 ns / 1 ns

`include "sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v"
`include "uart_agent.v"
module user_aes_tb;

reg clock;
reg wb_rst_i;
reg power1, power2;
reg power3, power4;

reg        wbd_ext_cyc_i;  // strobe/request
reg        wbd_ext_stb_i;  // strobe/request
reg [31:0] wbd_ext_adr_i;  // address
reg        wbd_ext_we_i;  // write
reg [31:0] wbd_ext_dat_i;  // data output
reg [3:0]  wbd_ext_sel_i;  // byte enable

wire [31:0] wbd_ext_dat_o;  // data input
wire        wbd_ext_ack_o;  // acknowlegement
wire        wbd_ext_err_o;  // error

// User I/O
wire [37:0] io_oeb;
wire [37:0] io_out;
wire [37:0] io_in;

wire gpio;
wire [37:0] mprj_io;
wire [7:0] mprj_io_0;
reg         test_fail;
reg [31:0] read_data;
integer    d_risc_id;

//----------------------------------
// Uart Configuration
// ---------------------------------
reg [1:0]      uart_data_bit        ;
reg	       uart_stop_bits       ; // 0: 1 stop bit; 1: 2 stop bit;
reg	       uart_stick_parity    ; // 1: force even parity
reg	       uart_parity_en       ; // parity enable
reg	       uart_even_odd_parity ; // 0: odd parity; 1: even parity

reg [7:0]      uart_data            ;
reg [15:0]     uart_divisor         ;	// divided by n * 16
reg [15:0]     uart_timeout         ;// wait time limit

reg [15:0]     uart_rx_nu           ;
reg [15:0]     uart_tx_nu           ;
reg [7:0]      uart_write_data [0:39];
reg 	       uart_fifo_enable     ;	// fifo mode disable


	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 clock <= (clock === 1'b0);

     /************* Port-B Mapping **********************************
     *   Pin-14       PB0/CLKO/ICP1             digital_io[11]
     *   Pin-15       PB1/SS[1]OC1A(PWM3)       digital_io[12]
     *   Pin-16       PB2/SS[0]/OC1B(PWM4)      digital_io[13]
     *   Pin-17       PB3/MOSI/OC2A(PWM5)       digital_io[14]
     *   Pin-18       PB4/MISO                  digital_io[15]
     *   Pin-19       PB5/SCK                   digital_io[16]
     *   Pin-9        PB6/XTAL1/TOSC1           digital_io[6]
     *   Pin-10       PB7/XTAL2/TOSC2           digital_io[7]
     *   ********************************************************/

     wire [7:0]  port_b_in = {   io_out[7],
		                 io_out[6],
		                 io_out[16],
		                 io_out[15],
			         io_out[14],
			         io_out[13],
		                 io_out[12],
		                 io_out[11]
			     };
	initial begin
		test_fail = 0;
		clock = 0;
                wbd_ext_cyc_i ='h0;  // strobe/request
                wbd_ext_stb_i ='h0;  // strobe/request
                wbd_ext_adr_i ='h0;  // address
                wbd_ext_we_i  ='h0;  // write
                wbd_ext_dat_i ='h0;  // data output
                wbd_ext_sel_i ='h0;  // byte enable
	end

	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(2, user_aes_tb);
	   	$dumpvars(0, user_aes_tb.u_top.u_riscv_top);
	   	$dumpvars(0, user_aes_tb.u_top.u_uart_i2c_usb_spi.u_uart0_core);
	   end
       `endif

	initial begin

	       $value$plusargs("risc_core_id=%d", d_risc_id);

               uart_data_bit           = 2'b11;
               uart_stop_bits          = 0; // 0: 1 stop bit; 1: 2 stop bit;
               uart_stick_parity       = 0; // 1: force even parity
               uart_parity_en          = 0; // parity enable
               uart_even_odd_parity    = 1; // 0: odd parity; 1: even parity
               uart_divisor            = 15;// divided by n * 16
               uart_timeout            = 500;// wait time limit
               uart_fifo_enable        = 0;	// fifo mode disable

               #200; // Wait for reset removal
               repeat (10) @(posedge clock);
               $display("Monitor: Standalone User Uart Test Started");
               
               // Remove Wb Reset
               wb_user_core_write(`ADDR_SPACE_WBHOST+`WBHOST_GLBL_CFG,'h1);

               // Enable UART Multi Functional Ports
               wb_user_core_write(`ADDR_SPACE_GLBL+`GLBL_CFG_MUTI_FUNC,'h100);
               
               repeat (2) @(posedge clock);
               #1;
		// Remove all the reset
		if(d_risc_id == 0) begin
		     $display("STATUS: Working with Risc core 0");
                     wb_user_core_write(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG0,'h11F);
		end else if(d_risc_id == 1) begin
		     $display("STATUS: Working with Risc core 1");
                     wb_user_core_write(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG0,'h21F);
		end 

               repeat (100) @(posedge clock);  // wait for Processor Get Ready

               tb_uart.uart_init;
               wb_user_core_write(`ADDR_SPACE_UART0+8'h0,{3'h0,2'b00,1'b1,1'b1,1'b1});  
               tb_uart.control_setup (uart_data_bit, uart_stop_bits, uart_parity_en, uart_even_odd_parity, 
                                              uart_stick_parity, uart_timeout, uart_divisor);

		// Set the PORT-B Direction as Output
                wb_user_core_write(`ADDR_SPACE_GPIO+`GPIO_CFG_DSEL,'h0000FF00);
		// Set the GPIO Output data: 0x00000000
                wb_user_core_write(`ADDR_SPACE_GPIO+`GPIO_CFG_ODATA,'h0000000);
   
               fork
	          begin
                     repeat (1400000) @(posedge clock); 
	          end
	          begin
                     wait(port_b_in == 8'h18);
	          end
               join_any
	
	       wb_user_core_read_check(`ADDR_SPACE_GLBL+`GLBL_CFG_SOFT_REG_0,read_data,32'h00000000);

               $display("###################################################");
               if(test_fail == 0) begin
                  `ifdef GL
                      $display("Monitor: Standalone User AES Test (GL) Passed");
                  `else
                      $display("Monitor: Standalone User AES Test (RTL) Passed");
                  `endif
               end else begin
                   `ifdef GL
                       $display("Monitor: Standalone User AES Test (GL) Failed");
                   `else
                       $display("Monitor: Standalone User AES Test (RTL) Failed");
                   `endif
                end
               $display("###################################################");
               #100
               $finish;

	end

	initial begin
		wb_rst_i <= 1'b1;
		#100;
		wb_rst_i <= 1'b0;	    	// Release reset
	end
wire USER_VDD1V8 = 1'b1;
wire VSS = 1'b0;

user_project_wrapper u_top(
`ifdef USE_POWER_PINS
    .vccd1(USER_VDD1V8),	// User area 1 1.8V supply
    .vssd1(VSS),	// User area 1 digital ground
`endif
    .wb_clk_i        (clock),  // System clock
    .user_clock2     (1'b1),  // Real-time clock
    .wb_rst_i        (wb_rst_i),  // Regular Reset signal

    .wbs_cyc_i   (wbd_ext_cyc_i),  // strobe/request
    .wbs_stb_i   (wbd_ext_stb_i),  // strobe/request
    .wbs_adr_i   (wbd_ext_adr_i),  // address
    .wbs_we_i    (wbd_ext_we_i),  // write
    .wbs_dat_i   (wbd_ext_dat_i),  // data output
    .wbs_sel_i   (wbd_ext_sel_i),  // byte enable

    .wbs_dat_o   (wbd_ext_dat_o),  // data input
    .wbs_ack_o   (wbd_ext_ack_o),  // acknowlegement

 
    // Logic Analyzer Signals
    .la_data_in      ('1) ,
    .la_data_out     (),
    .la_oenb         ('0),
 

    // IOs
    .io_in          (io_in)  ,
    .io_out         (io_out) ,
    .io_oeb         (io_oeb) ,

    .user_irq       () 

);

`ifndef GL // Drive Power for Hold Fix Buf
    // All standard cell need power hook-up for functionality work
    initial begin

    end
`endif    

//------------------------------------------------------
//  Integrate the Serial flash with qurd support to
//  user core using the gpio pads
//  ----------------------------------------------------

   wire flash_clk = io_out[24];
   wire flash_csb = io_out[25];
   // Creating Pad Delay
   wire #1 io_oeb_29 = io_oeb[29];
   wire #1 io_oeb_30 = io_oeb[30];
   wire #1 io_oeb_31 = io_oeb[31];
   wire #1 io_oeb_32 = io_oeb[32];
   tri  #1 flash_io0 = (io_oeb_29== 1'b0) ? io_out[29] : 1'bz;
   tri  #1 flash_io1 = (io_oeb_30== 1'b0) ? io_out[30] : 1'bz;
   tri  #1 flash_io2 = (io_oeb_31== 1'b0) ? io_out[31] : 1'bz;
   tri  #1 flash_io3 = (io_oeb_32== 1'b0) ? io_out[32] : 1'bz;

   assign io_in[29] = flash_io0;
   assign io_in[30] = flash_io1;
   assign io_in[31] = flash_io2;
   assign io_in[32] = flash_io3;

   // Quard flash
     s25fl256s #(.mem_file_name("user_aes.hex"),
	         .otp_file_name("none"),
                 .TimingModel("S25FL512SAGMFI010_F_30pF")) 
		 u_spi_flash_256mb (
           // Data Inputs/Outputs
       .SI      (flash_io0),
       .SO      (flash_io1),
       // Controls
       .SCK     (flash_clk),
       .CSNeg   (flash_csb),
       .WPNeg   (flash_io2),
       .HOLDNeg (flash_io3),
       .RSTNeg  (!wb_rst_i)

       );


//---------------------------
//  UART Agent integration
// --------------------------
wire uart_txd,uart_rxd;

assign uart_txd   = io_out[2];
assign io_in[1]  = uart_rxd ;
 
uart_agent tb_uart(
	.mclk                (clock              ),
	.txd                 (uart_rxd           ),
	.rxd                 (uart_txd           )
	);


task wb_user_core_write;
input [31:0] address;
input [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h1;  // write
  wbd_ext_dat_i =data;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  $display("DEBUG WB USER ACCESS WRITE Address : %x, Data : %x",address,data);
  repeat (2) @(posedge clock);
end
endtask

task  wb_user_core_read;
input [31:0] address;
output [31:0] data;
reg    [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='0;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  repeat (1) @(negedge clock);
  data  = wbd_ext_dat_o;  
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  $display("DEBUG WB USER ACCESS READ Address : %x, Data : %x",address,data);
  repeat (2) @(posedge clock);
end
endtask

task  wb_user_core_read_check;
input [31:0] address;
output [31:0] data;
input [31:0] cmp_data;
reg    [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='0;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  repeat (1) @(negedge clock);
  data  = wbd_ext_dat_o;  
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  if(data !== cmp_data) begin
     $display("ERROR : WB USER ACCESS READ  Address : 0x%x, Exd: 0x%x Rxd: 0x%x ",address,cmp_data,data);
     test_fail = 1;
  end else begin
     $display("STATUS: WB USER ACCESS READ  Address : 0x%x, Data : 0x%x",address,data);
  end
  repeat (2) @(posedge clock);
end
endtask

`ifdef GL

wire        wbd_spi_stb_i   = u_top.u_qspi_master.wbd_stb_i;
wire        wbd_spi_ack_o   = u_top.u_qspi_master.wbd_ack_o;
wire        wbd_spi_we_i    = u_top.u_qspi_master.wbd_we_i;
wire [31:0] wbd_spi_adr_i   = u_top.u_qspi_master.wbd_adr_i;
wire [31:0] wbd_spi_dat_i   = u_top.u_qspi_master.wbd_dat_i;
wire [31:0] wbd_spi_dat_o   = u_top.u_qspi_master.wbd_dat_o;
wire [3:0]  wbd_spi_sel_i   = u_top.u_qspi_master.wbd_sel_i;

wire        wbd_uart_stb_i  = u_top.u_uart_i2c_usb_spi.reg_cs;
wire        wbd_uart_ack_o  = u_top.u_uart_i2c_usb_spi.reg_ack;
wire        wbd_uart_we_i   = u_top.u_uart_i2c_usb_spi.reg_wr;
wire [8:0]  wbd_uart_adr_i  = u_top.u_uart_i2c_usb_spi.reg_addr;
wire [7:0]  wbd_uart_dat_i  = u_top.u_uart_i2c_usb_spi.reg_wdata;
wire [7:0]  wbd_uart_dat_o  = u_top.u_uart_i2c_usb_spi.reg_rdata;
wire        wbd_uart_sel_i  = u_top.u_uart_i2c_usb_spi.reg_be;

`endif

/**
`ifdef GL
//-----------------------------------------------------------------------------
// RISC IMEM amd DMEM Monitoring TASK
//-----------------------------------------------------------------------------

`define RISC_CORE  user_uart_tb.u_top.u_core.u_riscv_top

always@(posedge `RISC_CORE.wb_clk) begin
    if(`RISC_CORE.wbd_imem_ack_i)
          $display("RISCV-DEBUG => IMEM ADDRESS: %x Read Data : %x", `RISC_CORE.wbd_imem_adr_o,`RISC_CORE.wbd_imem_dat_i);
    if(`RISC_CORE.wbd_dmem_ack_i && `RISC_CORE.wbd_dmem_we_o)
          $display("RISCV-DEBUG => DMEM ADDRESS: %x Write Data: %x Resonse: %x", `RISC_CORE.wbd_dmem_adr_o,`RISC_CORE.wbd_dmem_dat_o);
    if(`RISC_CORE.wbd_dmem_ack_i && !`RISC_CORE.wbd_dmem_we_o)
          $display("RISCV-DEBUG => DMEM ADDRESS: %x READ Data : %x Resonse: %x", `RISC_CORE.wbd_dmem_adr_o,`RISC_CORE.wbd_dmem_dat_i);
end

`endif
**/
endmodule
`include "s25fl256s.sv"
`default_nettype wire
