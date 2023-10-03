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
////  User Risc Core Boot Validation                              ////
////                                                              ////
////  This file is part of the riscduino cores project            ////
////  https://github.com/dineshannayya/riscuino.git               ////
////  http://www.opencores.org/cores/riscuino/                    ////
////                                                              ////
////  Description                                                 ////
////    Validate gpio input                                       ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 12th June 2021, Dinesh A                            ////
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

`default_nettype none

`timescale 1 ns / 1 ps

`include "sram_23LC1024.v"
`include "is62wvs1288.v"
`include "user_params.svh"
`include "uart_agent.v"

`define TB_HEX "arduino_gpio_input.hex"
`define TB_TOP arduino_gpio_input_tb

module `TB_TOP;
	reg clock;
	reg RSTB;
	reg CSB;
	reg power1, power2;
	reg power3, power4;

	wire gpio;
	wire [37:0] mprj_io;
	wire [7:0] mprj_io_0;
	wire [15:0] checkbits;

    wire uart_txd,uart_rxd;
	reg            test_fail            ;
	integer    d_risc_id;
    //----------------------------------
    // Uart Configuration
    // ---------------------------------
    reg [1:0]      uart_data_bit        ;
    reg	           uart_stop_bits       ; // 0: 1 stop bit; 1: 2 stop bit;
    reg	           uart_stick_parity    ; // 1: force even parity
    reg	           uart_parity_en       ; // parity enable
    reg	           uart_even_odd_parity ; // 0: odd parity; 1: even parity
    
    reg [7:0]      uart_data            ;
    reg [15:0]     uart_divisor         ;	// divided by n * 16
    reg [15:0]     uart_timeout         ;// wait time limit
    
    reg [15:0]     uart_rx_nu           ;
    reg [15:0]     uart_tx_nu           ;
    reg [7:0]      uart_write_data [0:39];
    reg 	       uart_fifo_enable     ;	// fifo mode disable
	reg            flag                 ;

	reg [31:0]     check_sum            ;
    reg [31:0]     read_data            ;
        
        integer i,j;
	//---------------------------------
	
	assign checkbits = mprj_io[31:16];

	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

    pullup(mprj_io[3]); 
   
    reg  [23:0]   arduino_gpio; 
    assign  {mprj_io[4],
             mprj_io[2],
             mprj_io[1],
             mprj_io[12],
             mprj_io[11],
             mprj_io[5],
             mprj_io[27],
             mprj_io[26],
             mprj_io[25],
             mprj_io[24],
             mprj_io[23],
             mprj_io[22],
             mprj_io[21],
             mprj_io[20],
             mprj_io[19],
             mprj_io[18],
             mprj_io[17],
             mprj_io[16],
             mprj_io[15],
             mprj_io[14],
             mprj_io[13],
             mprj_io[10],
             mprj_io[9],
             mprj_io[8]} = arduino_gpio;


	`ifdef WFDUMP
        initial
        begin
           $dumpfile("simx.vcd");
           $dumpvars(0,`TB_TOP);
           $dumpvars(0,`TB_TOP.u_spi_flash_256mb);
           $dumpvars(0,`TB_TOP.u_sram);
           $dumpvars(1,`TB_TOP.u_top.mprj);
           $dumpvars(0,`TB_TOP.u_top.mprj.u_wb_host);
           $dumpvars(0,`TB_TOP.u_top.mprj.u_pinmux);
           $dumpvars(0,`TB_TOP.u_top.mprj.u_qspi_master);
           $dumpvars(0,`TB_TOP.u_top.mprj.u_riscv_top);
	       $display("Waveform Dump started");
        end
        `endif

        initial
        begin
        arduino_gpio            = 'h0;
        uart_data_bit           = 2'b11;
        uart_stop_bits          = 0; // 0: 1 stop bit; 1: 2 stop bit;
        uart_stick_parity       = 0; // 1: force even parity
        uart_parity_en          = 0; // parity enable
        uart_even_odd_parity    = 1; // 0: odd parity; 1: even parity
	    tb_set_uart_baud(50000000,1152000,uart_divisor);// 50Mhz Ref clock, Baud Rate: 230400
        uart_timeout            = 2000;// wait time limit
        uart_fifo_enable        = 0;	// fifo mode disable

        $value$plusargs("risc_core_id=%d", d_risc_id);

         init();

        $display("Status:  Waiting for RISCV Core Boot ... ");
        wait(`TB_TOP.u_top.mprj.u_pinmux.u_glbl_reg.reg_15 == 32'h1); // Wait for RISCV Boot Indication
        $display("Status:  RISCV Core is Booted ");

	    tb_uart.debug_mode = 0; // disable debug display
        tb_uart.uart_init;
        tb_uart.control_setup (uart_data_bit, uart_stop_bits,uart_stop_bits, uart_parity_en, uart_even_odd_parity, uart_stick_parity, uart_timeout, uart_divisor);

        test_fail = 0;
		check_sum = 0;
        fork
        begin
           for(i = 0; i < 24; i = i+1) begin
              arduino_gpio[i] = 1'b1; 
              $display("STATUS: Setting Pin: %d High",i+2);
              // Wait for UART Response from RISCV 
              read_data = 0;
              while(read_data != 32'hA)
              begin
                 tb_uart.read_char(read_data,flag);
		         if(flag == 0)  begin
		            $write ("%c",read_data);
		            check_sum = check_sum+read_data;
		         end
              end
           end
           for(i = 0; i < 24; i = i+1) begin
              arduino_gpio[i] = 1'b0; 
              $display("STATUS: Setting Pin: %d Low",i+2);
              // Wait for UART Response from RISCV 
              flag = 0;
              while(flag == 0)
              begin
                 tb_uart.read_char(read_data,flag);
		         if(flag == 0)  begin
		            $write ("%c",read_data);
		            check_sum = check_sum+read_data;
		         end
              end
           end
           test_fail = 0;
        end
        begin
           repeat (20000000) @(posedge clock);  // wait for Processor Get Ready
           test_fail = 1;
        end
        join_any


        
        tb_uart.report_status(uart_rx_nu, uart_tx_nu);
		$display("Total Rx Char: %d Check Sum : %x ",uart_rx_nu, check_sum);
        if(uart_rx_nu != 600) test_fail = 1;
        if(check_sum != 32'hb784 ) test_fail = 1;

        $display("###################################################");
        if(test_fail == 0) begin
           `ifdef GL
               $display("Monitor: %m (GL) Passed");
           `else
               $display("Monitor: %m (RTL) Passed");
           `endif
        end else begin
            `ifdef GL
                $display("Monitor: %m (GL) Failed");
            `else
                $display("Monitor: %m (RTL) Failed");
            `endif
         end
        $display("###################################################");
              #100
              $finish;
        end


//-------------------------------------
// Upto MPW_8 partial SRAM is not handled in
// QSPI, Any partial SRAM write access will corrupt the next valid bytes
//--------------------------------------------
event event_psram_wr;

always@(posedge clock)
begin
   if(`TB_TOP.u_top.mprj.u_qspi_master.wbd_stb_i == 1'b1 &&
      `TB_TOP.u_top.mprj.u_qspi_master.wbd_we_i  == 1'b1 && 
      `TB_TOP.u_top.mprj.u_qspi_master.wbd_sel_i != 4'hF && 
      `TB_TOP.u_top.mprj.u_qspi_master.wbd_ack_o == 1'b1 )
   begin
        $display("Partitial SRAM Write Detected at %t");
        -> event_psram_wr;
   end
end

	initial begin
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		#170000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end

	//always @(mprj_io) begin
	//	#1 $display("MPRJ-IO state = %b ", mprj_io[7:0]);
	//end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power3;
	wire USER_VDD1V8 = power4;
	wire VSS = 1'b0;

	caravel u_top (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (USER_VDD3V3),
		.vdda2    (USER_VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (USER_VDD1V8),
		.vccd2	  (USER_VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
        .mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("caravel_boot.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

//-----------------------------------------
// Connect Quad Flash to for usr Risc Core
//-----------------------------------------

   wire user_flash_clk = mprj_io[28];
   wire user_flash_csb = mprj_io[29];
   //tri  user_flash_io0 = mprj_io[26];
   //tri  user_flash_io1 = mprj_io[27];
   //tri  user_flash_io2 = mprj_io[28];
   //tri  user_flash_io3 = mprj_io[29];


   // Quard flash
     s25fl256s #(.mem_file_name(`TB_HEX),
	         .otp_file_name("none"), 
                 .TimingModel("S25FL512SAGMFI010_F_30pF")) 
		 u_spi_flash_256mb (
           // Data Inputs/Outputs
       .SI      (mprj_io[33]),
       .SO      (mprj_io[34]),
       // Controls
       .SCK     (user_flash_clk),
       .CSNeg   (user_flash_csb),
       .WPNeg   (mprj_io[35]),
       .HOLDNeg (mprj_io[36]),
       .RSTNeg  (RSTB)

       );

   wire spiram_csb = mprj_io[31];

   sram_23LC1024 #(.mem_file_name("none"))
	u_sram (
         // Data Inputs/Outputs
           .io0     (mprj_io[33]),
           .io1     (mprj_io[34]),
           // Controls
           .clk    (user_flash_clk),
           .csb    (spiram_csb),
           .io2    (mprj_io[35]),
           .io3    (mprj_io[36])
    );

assign uart_txd   = mprj_io[7];
assign mprj_io[6]  = uart_rxd ;
 
uart_agent tb_uart(
	.mclk                (clock              ),
	.txd                 (uart_rxd           ),
	.rxd                 (uart_txd           )
	);


`ifndef GL // Drive Power for Hold Fix Buf
    // All standard cell need power hook-up for functionality work
initial begin
end
`endif    
`include "caravel_task.sv"
endmodule
// SSFLASH has 1ps/1ps time scale
`include "s25fl256s.sv"
`default_nettype wire
