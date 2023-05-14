##############################################################################
## This file is part of 'LCLS2 LLRF Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 LLRF Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

import pyrogue as pr

class BsaMpsMsgRxCombine(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

        self.addRemoteVariables(
            name         = 'BsaData',
            description  = 'BsaData',
            offset       = 0x000,
            bitSize      = 32,
            mode         = 'RO',
            number       = 32,
            stride       = 4,
            pollInterval = 1,
        )

        self.addRemoteVariables(
            name         = 'BsaSevr',
            description  = 'BsaSevr',
            offset       = 0x080,
            bitSize      = 2,
            mode         = 'RO',
            number       = 32,
            stride       = 4,
            pollInterval = 1,
        )

        self.addRemoteVariables(
            name         = 'RemoteDropCnt',
            description  = 'Remote Drop Counter',
            offset       = 0x100,
            bitSize      = 32,
            mode         = 'RO',
            number       = 4,
            stride       = 16,
            pollInterval = 1,
        )

        self.addRemoteVariables(
            name         = 'RemoteTimestamp',
            description  = 'Remote Timestamp',
            offset       = 0x200,
            bitSize      = 64,
            mode         = 'RO',
            number       = 4,
            stride       = 16,
            pollInterval = 1,
        )

        self.add(pr.RemoteVariable(
            name         = 'LocalTimestamp',
            description  = 'Local Timestamp',
            offset       = 0x240,
            bitSize      = 64,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'PacketRate',
            description  = 'Diagnostic Bus Update Rate (units of Hz)',
            offset       = 0x300,
            units        = 'Hz',
            disp         = '{:d}',
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'CntRst',
            description  = 'Status Counter Reset',
            offset       = 0xFFC,
            bitSize      = 1,
            mode         = 'WO',
        ))

        self.add(pr.LocalCommand(
            name        = 'RstCnt',
            description = 'Reset all the status counters',
            function    = lambda: self.CntRst.set(1),
        ))
