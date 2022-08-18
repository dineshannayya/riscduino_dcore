/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */


#include "common_misc.h"
#include "common_bthread.h"
#include "../c_func/inc/int_reg_map.h"

#define SC_SIM_OUTPORT (0xf0000000)
#define uint32_t  long
#define uint16_t  int
#define size      10

  print_message(const char *fmt) {
      char ch;
     // Wait for Semaphore-lock=0
     while((reg_sema_lock0 & 0x1) == 0x0);
     while(ch = *(unsigned char *)fmt) {

        while((reg_uart0_status & 0x1) == 0x1);

	    reg_uart0_txdata = ch;
        ++fmt;
     }
     // Release Semaphore Lock
     reg_sema_lock0 = 0x1;

    // Added nop to Semaphore to acquire by other core
    asm ("nop");
    asm ("nop");
    asm ("nop");
    asm ("nop");


  }


 int main( int argc, char* argv[] )
 {
      char ch;

       // Common Sub-Routine 
       if ( bthread_get_core_id() == 0 ) {

         // Enable the GPIO UART I/F
         reg_glbl_multi_func = 0x100;

         // Enable the UART TX/RX & STOP=2
         reg_uart0_ctrl = 0x7;
         // 1152000 Baud at 50Mhz System clock
         reg_uart0_baud_ctrl1 = 0x0;
         reg_uart0_baud_ctrl2 = 0x0;

         reg_glbl_soft_reg_5 = 0x1; // Test Start Indication
       }
       // Core 0 thread
       if ( bthread_get_core_id() == 0 ) {
         print_message("UART command-0 from core-0\n");
         print_message("UART command-1 from core-0\n");
         print_message("UART command-2 from core-0\n");
         print_message("UART command-3 from core-0\n");

       }
       // Core 1 thread
       if ( bthread_get_core_id() == 1 ) {

         while((reg_glbl_soft_reg_5 & 0x1) == 0x0); // wait for test start
         print_message("UART command-0 from core-1\n");
         print_message("UART command-1 from core-1\n");
         print_message("UART command-2 from core-1\n");
         print_message("UART command-3 from core-1\n");

       }
       // Core 2 thread
       if ( bthread_get_core_id() == 2 ) {
         while((reg_glbl_soft_reg_5 & 0x1) == 0x0); // wait for test start
         print_message("UART command-0 from core-2\n");
         print_message("UART command-1 from core-2\n");
         print_message("UART command-2 from core-2\n");
         print_message("UART command-3 from core-2\n");

       }
       // Core 3 thread
       if ( bthread_get_core_id() == 3 ) {
         while((reg_glbl_soft_reg_5 & 0x1) == 0x0); // wait for test start
         print_message("UART command-0 from core-3\n");
         print_message("UART command-1 from core-3\n");
         print_message("UART command-2 from core-3\n");
         print_message("UART command-3 from core-3\n");

       }
      
       return 0;
 }


