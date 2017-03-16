# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf

# Load source code 
loadSource -dir            "$::DIR_PATH/hdl/"
loadSource -sim_only -dir  "$::DIR_PATH/tb/"
loadSource -sim_only -path "$::DIR_PATH/../../common/AppCommon/core/BsaMpsMsgRxFramer.vhd"
loadSource -sim_only -path "$::DIR_PATH/../../common/AppCommon/core/BsaMpsMsgRxFramerReg.vhd"

# Configure the top-level RTL and simulation
set_property top "BsaMspMsgTxCore" [current_fileset]
set_property top "BsaMpsMsgGtx7Tb" [get_filesets sim_1]
