# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load the common RTL source
loadSource -dir "$::DIR_PATH/BsaMpsMsgTx/"
loadSource -dir "$::DIR_PATH/BsaMpsMsgRx/"

# Get the family type
set family [getFpgaFamily]

if { ${family} == "kintex7" } {
   loadSource -dir "$::DIR_PATH/BsaMpsMsgTx/ip/"
}

if { ${family} == "kintexu" } {   
   loadSource      -dir "$::DIR_PATH/app"   
   loadConstraints -dir "$::DIR_PATH/app/"
   
   loadSource -path "$::DIR_PATH/BsaMpsMsgRx/ip/BsaMpsGthCoreWrapper.vhd"
   loadSource -path "$::DIR_PATH/BsaMpsMsgRx/ip/BsaMpsMsgRxCore.vhd"
   loadSource -path "$::DIR_PATH/BsaMpsMsgRx/ip/BsaMpsGthCore.dcp"
   #loadIpCore -path "$::DIR_PATH/BsaMpsMsgRx/ip/BsaMpsGthCore.xci"; # Using the pre-built .DCP file   
}

