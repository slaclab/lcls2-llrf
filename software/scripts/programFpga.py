#-----------------------------------------------------------------------------
# This file is part of the 'LCLS2 AMC Carrier Firmware'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'LCLS2 AMC Carrier Firmware', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import setupLibPaths
import pyrogue as pr
import pyrogue.gui
import sys
import rogue
import pyrogue.protocols
import argparse
import time

import surf.axi as axi
import surf.devices.micron as micron

# Set the argument parser
parser = argparse.ArgumentParser()

# Add arguments
parser.add_argument(
    "--mcs",
    type     = str,
    required = True,
    help     = "path to mcs file",
)

parser.add_argument(
    "--ip",
    type     = str,
    required = True,
    help     = "IP address",
)

# Get the arguments
args = parser.parse_args()

class MyRoot(pr.Root):
    def __init__(   self,
            ipAddr = '10.0.0.101',
            **kwargs):
        super().__init__(**kwargs)

        self.udp = rogue.protocols.udp.Client(args.ip, 8192, 1500 )
        self.srp = rogue.protocols.srp.SrpV0()
        self.udp == self.srp

        self.add(axi.AxiVersion(
            name    = 'AxiVersion',
            memBase = self.srp,
            offset  = 0x00000000,
        ))

        self.add(micron.AxiMicronN25Q(
            name     = "MicronN25Q",
            memBase  = self.srp,
            offset   = 0x2000000,
            addrMode = True,
        ))

# Set base
base = MyRoot(
    name     = 'AMCc',
    pollEn   = False,
    initRead = False,
)

# Start the system
base.start()

# Create useful pointers
AxiVersion = base.AxiVersion
MicronN25Q = base.MicronN25Q

#-----------------------------------------------------------------------------

# # Reset the status register
# MicronN25Q.setPromStatusReg(0x0)
# if ( MicronN25Q.getPromStatusReg() != 0x0 ):
    # raise SysTestException( "Failed program FPGA PROM into FSBL hardware-protected mode (0x%x) \n\
                             # Error Probably due to not having the 2-pin jumper installed" % (MicronN25Q.getPromStatusReg()) )

#-----------------------------------------------------------------------------

print ( '###################################################')
print ( '#                 Old Firmware                    #')
print ( '###################################################')
AxiVersion.printStatus()

# Program the FPGA's PROM
MicronN25Q.LoadMcsFile(args.mcs)

if(MicronN25Q._progDone):
    print('\nReloading FPGA firmware from PROM ....')
    AxiVersion.FpgaReload()
    time.sleep(10)
    print('\nReloading FPGA done')

    print ( '###################################################')
    print ( '#                 New Firmware                    #')
    print ( '###################################################')
    AxiVersion.printStatus()
else:
    print('Failed to program FPGA')

#-----------------------------------------------------------------------------

# MicronN25Q.setPromStatusReg(0xE8)
# if ( MicronN25Q.getPromStatusReg() != 0xE8 ):
    # raise SysTestException( "Failed program FPGA PROM into FSBL hardware-protected mode (0x%x)" % (MicronN25Q.getPromStatusReg()) )

#-----------------------------------------------------------------------------

base.stop()
exit()
