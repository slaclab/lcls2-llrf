# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadRuckusTcl "$::DIR_PATH/surf"
loadRuckusTcl "$::DIR_PATH/lcls-timing-core"
loadRuckusTcl "$::DIR_PATH/amc-carrier-core"
loadRuckusTcl "$::DIR_PATH/../common/$::env(COMMON_FILE)"
loadSource -lib lcls2_llrf_bsa_mps_tx_core -path "$::DIR_PATH/lcls2-llrf-bsa-mps-tx-core/rtl/BsaMpsMsgTxFramer.vhd"
loadSource -lib lcls2_llrf_bsa_mps_tx_core -path "$::DIR_PATH/lcls2-llrf-bsa-mps-tx-core/rtl/BsaMpsMsgTxPacker.vhd"

# Remove unused .xdc files
remove_files  -fileset constrs_1 [get_files {AppTop.xdc}]
remove_files  -fileset constrs_1 [get_files {AmcMpsSfpBay0Pinout.xdc}]
remove_files  -fileset constrs_1 [get_files {AmcMpsSfpBay1Pinout.xdc}]

