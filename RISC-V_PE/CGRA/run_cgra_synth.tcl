# === Vivado Tcl Script for CGRA Synthesis ===
# Save this file as run_cgra_synth.tcl in your project folder

# === Project Setup ===
create_project cgra_project ./cgra_project -part xc7a200tfbg676-2 -force

# === Add Source Files ===
add_files [glob ./src/*.v]

# === Add Constraints File ===
add_files ./constraints/cgra_AC701.xdc

# === Set Top Module ===
set_property top bus_interface_memory_test_top [current_fileset]

# === Update Compile Order ===
update_compile_order -fileset sources_1

# === Launch Synthesis ===
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# === Open Synthesized Design ===
open_run synth_1

# === Generate Reports ===
report_utilization -file cgra_utilization.txt
report_timing_summary -file cgra_timing.txt
report_clock_networks -file cgra_clocks.txt
report_power -file cgra_power.txt
