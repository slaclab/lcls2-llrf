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
SetDebugCoreClk ${ilaName} {U_Core/U_Framer/txClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_Core/U_Gtx/cPllLock}
ConfigProbe ${ilaName} {U_Core/U_Gtx/U_Gtx7Core/txResetDoneOut}
ConfigProbe ${ilaName} {U_Core/U_Framer/sAxisMaster[tValid]}
ConfigProbe ${ilaName} {U_Core/U_Framer/sAxisMaster[tLast]}
ConfigProbe ${ilaName} {U_Core/U_Framer/sAxisMaster[tUser][*]}
ConfigProbe ${ilaName} {U_Core/U_Framer/sAxisMaster[tData][*]}
ConfigProbe ${ilaName} {U_Core/U_Framer/txDataK[*]}
ConfigProbe ${ilaName} {U_Core/U_Framer/txData[*]}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName} ${PROJ_DIR}/images/debug_probes.ltx
