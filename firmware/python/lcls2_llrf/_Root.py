##############################################################################
## This file is part of 'LCLS2 LLRF Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 LLRF Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

import rogue
import pyrogue.protocols

import pyrogue        as pr
import AmcCarrierCore as amccCore
import lcls2_llrf     as llrf

rogue.Version.minVersion('6.0.0')

class Root(pr.Root):
    def __init__(self,
            ip           = '10.0.0.107',
            backdoorComm = True,
            zmqSrvEn     = True,  # Flag to include the ZMQ server
            **kwargs):
        super().__init__(**kwargs)

        #################################################################
        if zmqSrvEn:
            self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='*', port=0)
            self.addInterface(self.zmqServer)

        #################################################################

        if ( backdoorComm ):

            # UDP only
            self.udp = rogue.protocols.udp.Client(ip,8192,0)

            # Connect the SRPv0 to RAW UDP
            self.srp = rogue.protocols.srp.SrpV0()
            self.srp == self.udp

        else:

            # Create SRP/ASYNC_MSG interface
            self.rudp = pyrogue.protocols.UdpRssiPack( name='rudpReg', host=ip, port=8193, packVer = 1, jumbo = False)

            # Connect the SRPv3 to tDest = 0x0
            self.srp = rogue.protocols.srp.SrpV3()
            self.srp == self.rudp.application(dest=0x0)

        #################################################################

        self.add(amccCore.AmcCarrierCore(
            memBase = self.srp,
            offset  = 0x00000000,
            # expand  =  True,
        ))

        self.add(llrf.Application(
            memBase = self.srp,
            offset  =  0x80000000,
            expand  =  True,
        ))

        #################################################################
