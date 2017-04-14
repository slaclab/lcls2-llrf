# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules

# Load target's source code and constraints
loadSource -sim_only -dir "$::DIR_PATH/tb/"

# Remove the .DCP and use the .XCI IP core instead
remove_files [get_files {BsaMpsGthCore.dcp}]
loadIpCore -path "$::env(TOP_DIR)/common/AppCommon/BsaMpsMsgRx/ip/BsaMpsGthCore.xci"

# Set the top level synth_1 and sim_1
set_property top "Application"   [current_fileset]
set_property top "ApplicationTb" [get_filesets sim_1]