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

import sys
import time
import argparse

import pyrogue as pr
import pyrogue.pydm

import lcls2_llrf as amcCarrier

#################################################################

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

# Set the argument parser
parser = argparse.ArgumentParser()

# Add arguments
parser.add_argument(
    "--backdoorComm",
    type     = argBool,
    required = False,
    default  = True,
    help     = "communication type",
)

parser.add_argument(
    "--ip",
    type     = str,
    required = False,
    default  = '10.0.0.107',
    help     = "IP address",
)

parser.add_argument(
    "--pollEn",
    type     = argBool,
    required = False,
    default  = True,
    help     = "Enable auto-polling",
)

parser.add_argument(
    "--initRead",
    type     = argBool,
    required = False,
    default  = True,
    help     = "Enable read all variables at start",
)

# Get the arguments
args = parser.parse_args()

#################################################################

with amcCarrier.Root(
    ip           = args.ip,
    backdoorComm = args.backdoorComm,
    pollEn       = args.pollEn,
    initRead     = args.initRead,
) as root:
    pyrogue.pydm.runPyDM(
        root  = root,
        sizeX = 800,
        sizeY = 600,
    )

#################################################################
