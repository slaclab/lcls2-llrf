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

# PC-379-396-09: Revision C02 (or later)
set_property PACKAGE_PIN AN4 [get_ports {gtTxP[0]}] ; #P11 PIN32
set_property PACKAGE_PIN AN3 [get_ports {gtTxN[0]}] ; #P11 PIN33
set_property PACKAGE_PIN AP2 [get_ports {gtRxP[0]}] ; #P11 PIN29
set_property PACKAGE_PIN AP1 [get_ports {gtRxN[0]}] ; #P11 PIN30
set_property PACKAGE_PIN AM6 [get_ports {gtTxP[1]}] ; #P11 PIN38
set_property PACKAGE_PIN AM5 [get_ports {gtTxN[1]}] ; #P11 PIN39
set_property PACKAGE_PIN AM2 [get_ports {gtRxP[1]}] ; #P11 PIN35
set_property PACKAGE_PIN AM1 [get_ports {gtRxN[1]}] ; #P11 PIN36

# # PC-379-396-09: Revision C01 (or earlier)
# set_property PACKAGE_PIN AH6 [get_ports {gtTxP[0]}] ; #P11 PIN47
# set_property PACKAGE_PIN AH5 [get_ports {gtTxN[0]}] ; #P11 PIN48
# set_property PACKAGE_PIN AH2 [get_ports {gtRxP[0]}] ; #P11 PIN44
# set_property PACKAGE_PIN AH1 [get_ports {gtRxN[0]}] ; #P11 PIN45
# set_property PACKAGE_PIN AG4 [get_ports {gtTxP[1]}] ; #P11 PIN53
# set_property PACKAGE_PIN AG3 [get_ports {gtTxN[1]}] ; #P11 PIN54
# set_property PACKAGE_PIN AF2 [get_ports {gtRxP[1]}] ; #P11 PIN50
# set_property PACKAGE_PIN AF1 [get_ports {gtRxN[1]}] ; #P11 PIN51

####################################
## Application Timing Constraints ##
####################################

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {timingRef}] -group [get_clocks -include_generated_clocks {ddrClkIn}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {timingRef}] -group [get_clocks -include_generated_clocks {fabClk}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/U_Core/U_DdrMem/MigCore_Inst/inst/u_ddr3_infrastructure/gen_mmcme3.u_mmcme_adv_inst/CLKOUT5]] -group [get_clocks -of_objects [get_pins U_Core/U_Core/U_AmcCorePll/PllGen.U_Pll/CLKOUT0]]

##########################
## Misc. Configurations ##
##########################
