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


#include "../c_func/inc/int_reg_map.h"
#include "common_misc.h"
#include "common_bthread.h"

#define SC_SIM_OUTPORT (0xf0000000)
#define uint32_t  long
#define uint16_t  int
#define size      10

// -------------------------------------------------------------------------
// Multi-core test, Two Array is filled with below data, destination hold sum
//      source           result            remark
//   src0    src1        dest              
//   0x00    0x0000      0x0000            updated by core-0
//   0x11    0x1100      0x1111            updated by core-0
//   0x22    0x2200      0x2222            updated by core-0
//   0x33    0x3300      0x3333            updated by core-0
//   0x44    0x4400      0x4444            updated by core-0
//   0x55    0x5500      0x5555            updated by core-0
//   0x66    0x6600      0x6666            updated by core-0
//   0x77    0x7700      0x7777            updated by core-0
//
//   0x88    0x8800      0x8888            updated by core-1
//   0x99    0x9900      0x9999            updated by core-1
//   0xAA    0xAA00      0xAAAA            updated by core-1
//   0xBB    0xBB00      0xBBBB            updated by core-1
//   0xCC    0xCC00      0xCCCC            updated by core-1
//   0xDD    0xDD00      0xDDDD            updated by core-1
//   0xEE    0xEE00      0xEEEE            updated by core-1
//   0xFF    0xFF00      0xFFFF            updated by core-1
//
// -------------------------------------------------------------------------

typedef struct {
    int* dest; // pointer to dest array
    int* src0; // pointer to src0 array
    int* src1; // pointer to src1 array
    int begin; // first element this core should process
    int end; // (one past) last element this core should process
} arg_t;


void vvadd_mt(void* arg_vptr )
 {

   // Cast void* to argument pointer.
   arg_t* arg_ptr = (arg_t*) arg_vptr;
   // Create local variables for each field of the argument structure.
   int* dest = arg_ptr->dest;
   int* src0 = arg_ptr->src0;
   int* src1 = arg_ptr->src1;
   int begin = arg_ptr->begin;
   int end = arg_ptr->end;

   // Do the actual work.
   for ( int i = begin; i < end; i++ ) {
      dest[i] = src0[i] + src1[i];
   }

 }

 #define buf_size 16

 int main( int argc, char* argv[] )
 {

       int dest[buf_size];
       int src0[buf_size];
       int src1[buf_size];
       char test_pass = 0x1;
       if ( bthread_get_core_id() == 0 ) {
           // GLBL_CFG_MAIL_BOX used as mail box, each core update boot up handshake at 8 bit
           // bit[7:0]   - core-0
           // bit[15:8]  - core-1
           // bit[23:16] - core-2
           // bit[31:24] - core-3
           reg_glbl_mail_box = 0x1 << (bthread_get_core_id() * 8); // Start of Main 

       }

       for ( int i = 0; i < buf_size; i++ ) {
          src0[i] = 0x1111 * (i); 
	  src1[i] = 0x11110000 * (i);
       }

       // Create two argument structures that include the array pointers and
       // what elements each core should process.
       arg_t arg0 = { dest, src0, src1, 0, buf_size/2 };
       arg_t arg1 = { dest, src0, src1, buf_size/2, buf_size };

       reg_mprj_globl_soft0  = 0x11223344;  // Sig-0
       // Initialize bare threads (bthread).
       bthread_init();
      
      
       reg_mprj_globl_soft1  = 0x22334455;  // Sig-1
       // Start counting stats.
       //test_stats_on();
      

       // Spawn work onto core 1
       bthread_spawn( 1, &vvadd_mt, &arg1 );
      
       reg_glbl_soft_reg_2  = 0x33445566;  // Sig-2
       // Have core 0 also do some work.
       vvadd_mt(&arg0);
      
       reg_glbl_soft_reg_3  = 0x44556677;  // Sig-3
       // Wait for core 1 to finish.
       bthread_join(1);


       // Stop counting stats
       //test_stats_off();
       reg_glbl_soft_reg_4 = 0x55667788;  // sig-4
      
       // Core 0 will verify the results.
       if ( bthread_get_core_id() == 0 ) {

	   // Check the Expected Data
           for ( int i = 0; i < buf_size; i++ ) {
              if(dest[i] != (src0[i] + src1[i]))
            	test_pass &= 0;
           }
	   if(test_pass == 0x1) {
               reg_glbl_soft_reg_5 = 0x66778899;  // sig-5
	   }

       }
       if ( bthread_get_core_id() == 0 ) {
           // GLBL_CFG_MAIL_BOX used as mail box, each core update boot up handshake at 8 bit
           // bit[7:0]   - core-0
           // bit[15:8]  - core-1
           // bit[23:16] - core-2
           // bit[31:24] - core-3
           reg_glbl_mail_box = 0xff << (bthread_get_core_id() * 8); // Start of Main 

       }
      
       return 0;
 }


