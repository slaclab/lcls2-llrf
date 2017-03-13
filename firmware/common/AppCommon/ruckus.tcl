# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Get the family type
set family [getFpgaFamily]

if { ${family} == "kintex7" } {
   loadSource -dir "$::DIR_PATH/BsaMpsMsgTx/"
}

if { ${family} == "kintexu" } {
   loadSource -dir "$::DIR_PATH/BsaMpsMsgRx/"
   loadSource -dir "$::DIR_PATH/core/"   
}

