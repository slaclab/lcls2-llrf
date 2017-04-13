##############################################################################
## This file is part of 'LCLS2 LLRF Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 LLRF Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

############################
## Open the synthesis design
############################
open_run synth_1

###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_0

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {U_App/clk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/gtwiz_reset_all_in[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/gtwiz_reset_rx_cdr_stable_out[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/gtwiz_reset_rx_datapath_in[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/gtwiz_reset_rx_done_out[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/gtwiz_reset_rx_pll_and_datapath_in[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/gtwiz_reset_tx_datapath_in[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/gtwiz_reset_tx_done_out[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/gtwiz_reset_tx_pll_and_datapath_in[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/loopback_in[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/rxbufreset_in[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/rxbufstatus_out[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/rxpmaresetdone_out[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/rxpolarity_in[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/GEN_REAL.U_BsaMpsGthCore/txpmaresetdone_out[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtReset}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtRst}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtRstOneShot}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName} ${PROJ_DIR}/images/debug_probes.ltx
