##############################################################################
## This file is part of 'LCLS2 LLRF Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 LLRF Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

import pyrogue    as pr
import lcls2_llrf as llrf

class Application(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

        for i in range(4):
            self.add(llrf.BsaMpsMsgRxCore(
                name   = f'BsaMpsMsgRxCore[{i}]',
                offset = i*0x10000000,
                # expand = True,
            ))

        self.add(llrf.BsaMpsMsgRxCombine(
            offset = 0x40000000,
            # expand = True,
        ))
