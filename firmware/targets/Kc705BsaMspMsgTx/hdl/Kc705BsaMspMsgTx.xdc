##############################################################################
## This file is part of 'LCLS2 LLRF Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 LLRF Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
# I/O Port Mapping
set_property -dict { PACKAGE_PIN AB7 IOSTANDARD LVCMOS15 } [get_ports {extRst}]

set_property -dict { PACKAGE_PIN AB8 IOSTANDARD LVCMOS15 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN AA8 IOSTANDARD LVCMOS15 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN AC9 IOSTANDARD LVCMOS15 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN AB9 IOSTANDARD LVCMOS15 } [get_ports {led[3]}]

set_property -dict { PACKAGE_PIN AE26 IOSTANDARD LVCMOS25 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN G19  IOSTANDARD LVCMOS25 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN E18  IOSTANDARD LVCMOS25 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN F16  IOSTANDARD LVCMOS25 } [get_ports {led[7]}]

set_property PACKAGE_PIN H2 [get_ports {gtTxP}] ; # SFP Cage
set_property PACKAGE_PIN H1 [get_ports {gtTxN}] ; # SFP Cage
set_property PACKAGE_PIN G4 [get_ports {gtRxP}] ; # SFP Cage
set_property PACKAGE_PIN G3 [get_ports {gtRxN}] ; # SFP Cage

set_property PACKAGE_PIN J8 [get_ports {gtClkP}] ; # GTX SMA CLK
set_property PACKAGE_PIN J7 [get_ports {gtClkN}] ; # GTX SMA CLK

set_property PACKAGE_PIN G8 [get_ports {stableClkP}]
set_property PACKAGE_PIN G7 [get_ports {stableClkN}]

# Timing Constraints 
create_clock -name stableClkP -period 8.000 [get_ports {stableClkP}]
create_clock -name gtClkP     -period 2.691 [get_ports {gtClkP}]
create_clock -name txClk      -period 5.384 [get_pins  {U_Core/U_Gtx/U_Gtx7Core/gtxe2_i/TXOUTCLK}]

set_clock_groups -asynchronous -group [get_clocks {txClk}] -group [get_clocks -include_generated_clocks {gtClkP}] 
set_clock_groups -asynchronous -group [get_clocks {txClk}] -group [get_clocks -include_generated_clocks {stableClkP}] 

# MISC.
set_property CFGBVS         {VCCO} [current_design]
set_property CONFIG_VOLTAGE {2.5}  [current_design]
