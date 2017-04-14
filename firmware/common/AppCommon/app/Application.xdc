##############################################################################
## This file is part of 'LCLS2 AMC Carrier Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 AMC Carrier Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######################
## Application Ports ##
#######################

set_property PACKAGE_PIN AN4 [get_ports {gtTxP[0]}] ; #P11 PIN32
set_property PACKAGE_PIN AN3 [get_ports {gtTxN[0]}] ; #P11 PIN33
set_property PACKAGE_PIN AP2 [get_ports {gtRxP[0]}] ; #P11 PIN29
set_property PACKAGE_PIN AP1 [get_ports {gtRxN[0]}] ; #P11 PIN30

set_property PACKAGE_PIN AM6 [get_ports {gtTxP[1]}] ; #P11 PIN38
set_property PACKAGE_PIN AM5 [get_ports {gtTxN[1]}] ; #P11 PIN39
set_property PACKAGE_PIN AM2 [get_ports {gtRxP[1]}] ; #P11 PIN35
set_property PACKAGE_PIN AM1 [get_ports {gtRxN[1]}] ; #P11 PIN36

####################################
## Application Timing Constraints ##
####################################

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {timingRef}] -group [get_clocks -include_generated_clocks {ddrClkIn}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {timingRef}] -group [get_clocks -include_generated_clocks {fabClk}]

##########################
## Misc. Configurations ##
##########################
