# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load the RTL souce code
loadSource -dir "$::DIR_PATH/core/"   
  
# Use the IP core for GTH module
# loadSource -path "$::DIR_PATH/ip/BsaMpsGthCore.dcp"
loadIpCore -path "$::DIR_PATH/ip/BsaMpsGthCore.xci"; # Using the pre-built .DCP file


