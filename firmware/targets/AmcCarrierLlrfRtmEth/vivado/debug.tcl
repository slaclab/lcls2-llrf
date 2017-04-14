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
# SetDebugCoreClk ${ilaName} {U_App/axilClk}
SetDebugCoreClk ${ilaName} {U_App/clk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_App/U_ClockManager/locked}

ConfigProbe ${ilaName} {U_App/txData[*]}
ConfigProbe ${ilaName} {U_App/txDataK[*]}

ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxBufStatus[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxData[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxdataK[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxDecErr[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxDispErr[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/cPllLock}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxValid}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtReset}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtRst}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtRst}
ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtRstOneShot}

ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxBufStatus[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxData[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxdataK[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxDecErr[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxDispErr[*]}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/cPllLock}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxValid}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/wdtReset}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/wdtRst}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/wdtRst}
ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/wdtRstOneShot}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName} ${PROJ_DIR}/images/debug_probes.ltx
