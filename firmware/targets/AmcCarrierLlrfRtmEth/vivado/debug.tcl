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

SetDebugCoreClk ${ilaName} {U_App/axilClk}
# SetDebugCoreClk ${ilaName} {U_App/clk}

#######################
## Set the debug Probes
#######################

# ConfigProbe ${ilaName} {U_App/timingBus[strobe]}
# ConfigProbe ${ilaName} {U_App/timingBus[message][timeStamp][*]}

ConfigProbe ${ilaName} {U_App/U_Combine/r[state][*]}
ConfigProbe ${ilaName} {U_App/U_Combine/r[diagnosticBus][strobe]}
ConfigProbe ${ilaName} {U_App/U_Combine/r[diagnosticBus][timingMessage][timeStamp][*]}
ConfigProbe ${ilaName} {U_App/U_Combine/r[aligned][*]}
ConfigProbe ${ilaName} {U_App/U_Combine/r[sevr][0][*]}
ConfigProbe ${ilaName} {U_App/U_Combine/r[sevr][1][*]}

ConfigProbe ${ilaName} {U_App/U_Combine/remoteValid[*]}
ConfigProbe ${ilaName} {U_App/U_Combine/remoteMsg[0][timeStamp][*]}
ConfigProbe ${ilaName} {U_App/U_Combine/remoteMsg[1][timeStamp][*]}
ConfigProbe ${ilaName} {U_App/U_Combine/r[remoteRd][*]}

ConfigProbe ${ilaName} {U_App/U_Combine/fifoValid}
ConfigProbe ${ilaName} {U_App/U_Combine/timingMessage[timeStamp][*]}
ConfigProbe ${ilaName} {U_App/U_Combine/fifoRd}
ConfigProbe ${ilaName} {U_App/U_Combine/progFull}

# ConfigProbe ${ilaName} {U_App/U_ClockManager/locked}

# ConfigProbe ${ilaName} {U_App/txData[*]}
# ConfigProbe ${ilaName} {U_App/txDataK[*]}

# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxBufStatus[*]}

# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/data[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/dataK[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/decErr[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/dispErr[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxBuff[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/cnt[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxReset}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/linkUp}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/dataValid}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtRst}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtReset}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/wdtRstOneShot}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/rxRstDone}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[0].U_BsaMpsMsgRx/U_Gth/txRstDone}

# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxBufStatus[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/data[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/dataK[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/decErr[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/dispErr[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxBuff[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/cnt[*]}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxReset}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/linkUp}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/dataValid}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/wdtRst}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/wdtReset}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/wdtRstOneShot}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/rxRstDone}
# ConfigProbe ${ilaName} {U_App/GEN_VEC[1].U_BsaMpsMsgRx/U_Gth/txRstDone}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName} ${PROJ_DIR}/images/debug_probes.ltx
