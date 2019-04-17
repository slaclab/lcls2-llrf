# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/lcls2-llrf-bsa-mps-tx-core

# Load target's source code and constraints
loadSource -sim_only -dir "$::DIR_PATH/tb/"
loadSource -sim_only -dir "$::DIR_PATH/../../common/AppCommon/BsaMpsMsgRx"

# Set the top level synth_1 and sim_1
set_property top "BsaMspMsgTxCore" [current_fileset]
set_property top "BsaMpsMsgGtx7Tb" [get_filesets sim_1]