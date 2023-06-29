Reference: https://github.com/AUCOHL/Lighter

Generate the Yosys plugin using the following command:

yosys-config --build cg_plugin.so clock_gating_plugin.cc


Run your Yosys synthesis script as follows:

yosys -m cg_plugin.so your_script.ys

Or TCL synthesis script as follows:

yosys -m cg_plugin.so your_script.tcl


For example:

read_verilog design
read_verilog sky130_clkg_blackbox.v
hierarchy -check
reg_clock_gating -map sky130_ff_map.v
synth -top design
dfflibmap -liberty lib/sky130_hd.lib 
abc -D 1250 -liberty lib/sky130_hd.lib 
splitnets
opt_clean -purge
opt;; 
write_verilog -noattr -noexpr -nohex -nodec -defparam   design.gl.v

