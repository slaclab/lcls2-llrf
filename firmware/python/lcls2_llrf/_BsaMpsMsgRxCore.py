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

class BsaMpsMsgRxCore(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name         = 'RxLinkUpCnt',
            description  = 'RxLinkUp Status Counter',
            offset       = 0x000,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'RxDecErr0Cnt',
            description  = 'RxDecErr0 Status Counter',
            offset       = 0x004,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'RxDecErr1Cnt',
            description  = 'RxDecErr1 Status Counter',
            offset       = 0x008,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'RxDispErr0Cnt',
            description  = 'RxDispErr0 Status Counter',
            offset       = 0x00C,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'RxDispErr1Cnt',
            description  = 'RxDispErr1 Status Counter',
            offset       = 0x010,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'OverflowCntCnt',
            description  = 'OverflowCnt Status Counter',
            offset       = 0x014,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'ErrPktLenCnt',
            description  = 'ErrPktLenCnt Status Counter',
            offset       = 0x018,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'ErrCrcCnt',
            description  = 'ErrCrc Status Counter',
            offset       = 0x01C,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'CPllLockCnt',
            description  = 'CPllLock Status Counter',
            offset       = 0x020,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'GtRxFifoErrCnt',
            description  = 'GtRxFifoErr Status Counter',
            offset       = 0x024,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'RxLinkUp',
            description  = 'RxLinkUp Status Counter',
            offset       = 0x400,
            bitSize      = 1,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'CPllLock',
            description  = 'CPllLock Status Counter',
            offset       = 0x401,
            bitSize      = 1,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'PacketRate',
            description  = 'Packet Rate (units of Hz)',
            offset       = 0x410,
            units        = 'Hz',
            disp         = '{:d}',
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'SofRate',
            description  = 'Start-Of-Frame Rate (units of Hz)',
            offset       = 0x414,
            units        = 'Hz',
            disp         = '{:d}',
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'UserValue',
            description  = 'Remote UserValue Status Counter',
            offset       = 0x500,
            bitSize      = 128,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'RxPolarity',
            description  = 'GTH RxPolarity',
            offset       = 0x700,
            bitSize      = 1,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'TxPolarity',
            description  = 'GTH TxPolarity',
            offset       = 0x704,
            bitSize      = 1,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'Loopback',
            description  = 'GTH Loopback',
            offset       = 0x708,
            bitSize      = 1,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'RollOverEn',
            description  = 'Status counters roll over enable bit mask',
            offset       = 0x7F0,
            bitSize      = 10,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'CntRst',
            description  = 'Status Counter Reset',
            offset       = 0x7F4,
            bitSize      = 1,
            mode         = 'WO',
        ))

        self.add(pr.RemoteVariable(
            name         = 'GtRst',
            description  = 'GTH Reset',
            offset       = 0x7F8,
            bitSize      = 1,
            mode         = 'WO',
        ))

        self.add(pr.RemoteVariable(
            name         = 'HardRst',
            description  = 'Hard Reset',
            offset       = 0x7FC,
            bitSize      = 1,
            mode         = 'WO',
        ))

        self.add(pr.LocalCommand(
            name        = 'RstCnt',
            description = 'Reset all the status counters',
            function    = lambda: self.CntRst.set(1),
        ))

        self.add(pr.LocalCommand(
            name        = 'RstGt',
            description = 'Reset the GTH',
            function    = lambda: self.GtRst.set(1),
        ))

        self.add(pr.LocalCommand(
            name        = 'RstHard',
            description = 'Reset the registers to default values',
            function    = lambda: self.HardRst.set(1),
        ))

        self.addRemoteVariables(
            name         = 'BsaQuantity',
            description  = 'BsaQuantity',
            offset       = 0x800,
            bitSize      = 32,
            mode         = 'RO',
            number       = 12,
            stride       = 4,
            pollInterval = 1,
        )

        self.addRemoteVariables(
            name         = 'BsaSevr',
            description  = 'BsaSevr',
            offset       = 0x840,
            bitSize      = 2,
            mode         = 'RO',
            number       = 12,
            stride       = 4,
            pollInterval = 1,
        )

        self.add(pr.RemoteVariable(
            name         = 'MpsPermit',
            description  = 'Remote MpsPermit',
            offset       = 0x900,
            bitSize      = 8,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'RemoteTimestamp',
            description  = 'Remote Timestamp',
            offset       = 0x910,
            bitSize      = 64,
            mode         = 'RO',
            pollInterval = 1,
        ))

    def hardReset(self):
        self.HardRst.set(1)

    def countReset(self):
        self.CntRst.set(1)
