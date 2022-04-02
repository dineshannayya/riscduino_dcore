###############################################################################
# Timing Constraints
###############################################################################
create_clock -name core_clk -period 20.0000 [get_ports {core_clk}]
create_clock -name rtc_clk -period 40.0000 [get_ports {rtc_clk}]
create_clock -name wb_clk -period 10.0000 [get_ports {wb_clk}]

set_clock_transition 0.1500 [all_clocks]
set_clock_uncertainty -setup 0.2500 [all_clocks]
set_clock_uncertainty -hold 0.2500 [all_clocks]

set ::env(SYNTH_TIMING_DERATE) 0.05
puts "\[INFO\]: Setting timing derate to: [expr {$::env(SYNTH_TIMING_DERATE) * 10}] %"
set_timing_derate -early [expr {1-$::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late [expr {1+$::env(SYNTH_TIMING_DERATE)}]

set_clock_groups -name async_clock -asynchronous \
 -group [get_clocks {core_clk}]\
 -group [get_clocks {rtc_clk}]\
 -group [get_clocks {wb_clk}] -comment {Async Clock group}

###############################################################################
# Environment
###############################################################################
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin $::env(SYNTH_DRIVING_CELL_PIN) [all_inputs]
set cap_load [expr $::env(SYNTH_CAP_LOAD) / 1000.0]
puts "\[INFO\]: Setting load to: $cap_load"
set_load  $cap_load [all_outputs]

###############################################################################
# Design Rules
###############################################################################
