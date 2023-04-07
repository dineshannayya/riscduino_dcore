# SPDX-FileCopyrightText:  2021 , Dinesh Annayya
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
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileContributor: Modified by Dinesh Annayya <dinesha@opencores.org>

# Global
# ------

set script_dir [file dirname [file normalize [info script]]]
# Name

set ::env(DESIGN_NAME) pinmux_top

set ::env(DESIGN_IS_CORE) "0"
set ::env(FP_PDN_CORE_RING) "0"

# Timing configuration
set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_PORT) "mclk"

set ::env(SYNTH_MAX_FANOUT) 4
set ::env(SYNTH_BUFFERING) {0}

## CTS BUFFER
set ::env(CTS_CLK_MAX_WIRE_LENGTH) {250}
set ::env(CTS_CLK_BUFFER_LIST) "sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8"
set ::env(CTS_SINK_CLUSTERING_SIZE) "16"
set ::env(CLOCK_BUFFER_FANOUT) "8"

# Sources
# -------

# Local sources + no2usb sources
set ::env(VERILOG_FILES) "\
     $::env(DESIGN_DIR)/../../verilog/rtl/lib/clk_skew_adjust.gv \
     $::env(DESIGN_DIR)/../../verilog/rtl/pinmux/src/pinmux_top.sv     \
     $::env(DESIGN_DIR)/../../verilog/rtl/pinmux/src/pinmux.sv     \
     $::env(DESIGN_DIR)/../../verilog/rtl/pinmux/src/glbl_reg.sv  \
     $::env(DESIGN_DIR)/../../verilog/rtl/pinmux/src/pseudorandom.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/gpio/src/gpio_top.sv  \
     $::env(DESIGN_DIR)/../../verilog/rtl/gpio/src/gpio_reg.sv  \
     $::env(DESIGN_DIR)/../../verilog/rtl/gpio/src/gpio_intr.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/gpio/src/gpio_dglicth.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/pwm/src/pwm_top.sv   \
     $::env(DESIGN_DIR)/../../verilog/rtl/pwm/src/pwm_core.sv   \
     $::env(DESIGN_DIR)/../../verilog/rtl/pwm/src/pwm_glbl_reg.sv   \
     $::env(DESIGN_DIR)/../../verilog/rtl/pwm/src/pwm_blk_reg.sv   \
     $::env(DESIGN_DIR)/../../verilog/rtl/pwm/src/pwm_cfg_dglitch.sv   \
     $::env(DESIGN_DIR)/../../verilog/rtl/pwm/src/pwm.sv       \
     $::env(DESIGN_DIR)/../../verilog/rtl/timer/src/timer_top.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/timer/src/timer_reg.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/timer/src/timer.sv     \
     $::env(DESIGN_DIR)/../../verilog/rtl/pinmux/src/semaphore_reg.sv  \
     $::env(DESIGN_DIR)/../../verilog/rtl/ws281x/src/ws281x_top.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/ws281x/src/ws281x_driver.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/ws281x/src/ws281x_reg.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/pinmux/src/strap_ctrl.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/pinmux/src/glbl_rst_reg.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/dig2ana/src/dig2ana_reg.sv \
     $::env(DESIGN_DIR)/../../verilog/rtl/lib/pulse_gen_type1.sv   \
     $::env(DESIGN_DIR)/../../verilog/rtl/lib/pulse_gen_type2.sv   \
     $::env(DESIGN_DIR)/../../verilog/rtl/lib/registers.v          \
     $::env(DESIGN_DIR)/../../verilog/rtl/lib/ctech_cells.sv     \
     $::env(DESIGN_DIR)/../../verilog/rtl/lib/reset_sync.sv     \
     $::env(DESIGN_DIR)/../../verilog/rtl/lib/sync_fifo.sv     \
     $::env(DESIGN_DIR)/../../verilog/rtl/lib/clk_ctl.v     \
     "

set ::env(VERILOG_INCLUDE_DIRS) [glob $::env(DESIGN_DIR)/../../verilog/rtl/ ]

set ::env(SYNTH_DEFINES) [list SYNTHESIS  YCR_DBG_EN]
set ::env(SYNTH_READ_BLACKBOX_LIB) 1
set ::env(SDC_FILE) $::env(DESIGN_DIR)/base.sdc
set ::env(BASE_SDC_FILE) $::env(DESIGN_DIR)/base.sdc

set ::env(LEC_ENABLE) 0

set ::env(VDD_PIN) [list {vccd1}]
set ::env(GND_PIN) [list {vssd1}]


# Floorplanning
# -------------

set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 520 800"


# If you're going to use multiple power domains, then keep this disabled.
set ::env(RUN_CVC) 0

#set ::env(PDN_CFG) $script_dir/pdn.tcl


set ::env(PL_TIME_DRIVEN) 1
set ::env(PL_TARGET_DENSITY) "0.36"
set ::env(CELL_PAD) "8"
set ::env(GRT_ADJUSTMENT) {0.1}


######################################################################################
# Metal-2/3 Signal are Routed near to block boundary is creating DRC violation at Top-level 
# during pad connectivity

#set ::env(GRT_OBS) "                        \
#                    met2  0    2   500  3,  \
#                    met2  0    747 500  748, \
#                    met3  2    0   3    750, \
#                    met3  497  0 498    750"


# helps in anteena fix
set ::env(USE_ARC_ANTENNA_CHECK) "1"

set ::env(FP_IO_VEXTEND) 4
set ::env(FP_IO_HEXTEND) 4

set ::env(FP_PDN_VPITCH) 100
set ::env(FP_PDN_HPITCH) 100
set ::env(FP_PDN_VWIDTH) 6.2
set ::env(FP_PDN_HWIDTH) 6.2

#set ::env(GLB_RT_MAXLAYER) 5
set ::env(RT_MAX_LAYER) {met4}

#Lef 
set ::env(MAGIC_GENERATE_LEF) {1}
set ::env(MAGIC_WRITE_FULL_LEF) {0}

set ::env(DIODE_INSERTION_STRATEGY) 4


#LVS Issue - DEF Base looks to having issue
set ::env(MAGIC_EXT_USE_GDS) {1}

set ::env(GLB_RESIZER_MAX_SLEW_MARGIN) {1.5}
set ::env(PL_RESIZER_MAX_SLEW_MARGIN) {1.5}

set ::env(GLB_RESIZER_MAX_CAP_MARGIN) {0.25}
set ::env(PL_RESIZER_MAX_CAP_MARGIN) {0.25}

set ::env(GLB_RESIZER_MAX_WIRE_LENGTH) {500}
set ::env(PL_RESIZER_MAX_WIRE_LENGTH) {500}

set ::env(QUIT_ON_TIMING_VIOLATIONS) "0"
set ::env(QUIT_ON_MAGIC_DRC) "1"
set ::env(QUIT_ON_LVS_ERROR) "1"
set ::env(QUIT_ON_SLEW_VIOLATIONS) "0"
