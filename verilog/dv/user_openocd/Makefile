# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


# ---- Include Partitioned Makefiles ----

CONFIG = caravel_user_project
 
#######################################################################
## Caravel Verilog for Integration Tests
#######################################################################

DESIGNS?=../../..

export USER_PROJECT_VERILOG ?=  $(DESIGNS)/verilog
export USER_DV   ?=  $(USER_PROJECT_VERILOG)/dv

Q ?=@
IVERILOG_VPI_SRC = $(USER_DV)/common/vpi/jtag/jtag_common.c $(USER_DV)/common/vpi/jtag/jtag_vpi.c



## Simulation mode: RTL/GL
SIM?=RTL
DUMP?=OFF

### To Enable IVERILOG FST DUMP
export IVERILOG_DUMPER = fst


.SUFFIXES:

PATTERN = user_openocd

all:  ${PATTERN:=.vcd}


vvp:  ${PATTERN:=.vvp}


%.vvp: %_tb.v
	@echo '##### Building ######'
	$(Q)iverilog-vpi --name=jtag_vpi $(IVERILOG_VPI_SRC) 
	openocd -f riscduino.cfg
ifeq ($(SIM),RTL)
   ifeq ($(DUMP),OFF)
	iverilog -g2012 -DFUNCTIONAL -DSIM -I $(PDK_PATH) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.$(CONFIG) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.lib  \
	$< -o $@ 
    else  
	iverilog -g2012 -DWFDUMP -DFUNCTIONAL -DSIM -I $(PDK_PATH) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.$(CONFIG) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.lib  \
	$< -o $@ 
   endif
else  
   ifeq ($(DUMP),OFF)
	iverilog -g2012 -DFUNCTIONAL -DUSE_POWER_PINS -DGL -I $(PDK_PATH) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.gl.$(CONFIG) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.gl.lib \
	$< -o $@ 
    else  
	iverilog -g2012 -DWFDUMP -DFUNCTIONAL -DUSE_POWER_PINS -DGL -I $(PDK_PATH) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.gl.$(CONFIG) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.gl.lib \
	$< -o $@ 
   endif
endif

%.vcd: %.vvp
	$(Q)vvp -n -M. -mjtag_vpi $< +jtag_vpi_enable=1 &
	@sleep 30
	@echo '##### Running the test client ######'
	$(Q)openocd -f openocd.cfg
	@sleep 1



# ---- Clean ----

clean:
	rm -f *.elf *.hex *.bin *.vvp *.vcd *.log *.dump *.vpi *.o 

.PHONY: clean hex all
