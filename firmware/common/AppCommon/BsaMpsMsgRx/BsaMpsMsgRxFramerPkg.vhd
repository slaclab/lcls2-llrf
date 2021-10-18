-------------------------------------------------------------------------------
-- File       : BsaMpsMsgRxFramerPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: RX Data Framer Package File
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 LLRF Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 LLRF Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;

package BsaMpsMsgRxFramerPkg is

   constant RX_MSG_FIFO_WIDTH_C : positive := 480;

   type MsgType is record
      mpsPermit   : Slv2Array(3 downto 0);
      timeStamp   : slv(63 downto 0);
      bsaSevr     : Slv2Array(11 downto 0);
      bsaQuantity : Slv32Array(11 downto 0);
   end record MsgType;
   type MsgArray is array (natural range <>) of MsgType;
   constant MSG_INIT_C : MsgType := (
      mpsPermit   => (others => (others => '0')),
      timeStamp   => (others => '0'),
      bsaSevr     => (others => (others => '0')),
      bsaQuantity => (others => (others => '0')));

   function fromSlv (dout : slv(RX_MSG_FIFO_WIDTH_C-1 downto 0)) return MsgType;
   function toSlv (msg    : MsgType) return slv;

end package BsaMpsMsgRxFramerPkg;

package body BsaMpsMsgRxFramerPkg is

   function fromSlv (dout : slv(RX_MSG_FIFO_WIDTH_C-1 downto 0)) return MsgType is
      variable retVar : MsgType;
      variable i      : natural;
   begin
      -- Reset the variables
      retVar := MSG_INIT_C;

      -- Load the BSA Data
      for i in 11 downto 0 loop
         retVar.bsaQuantity(i) := dout((i*32)+31 downto (i*32));
      end loop;

      -- Load the time stamp
      retVar.timeStamp := dout(447 downto 384);

      -- Load the MPS permit
      for i in 3 downto 0 loop
         retVar.mpsPermit(i) := dout((i*2)+449 downto (i*2)+448);
      end loop;

      -- Load the BSA Severity
      for i in 11 downto 0 loop
         retVar.bsaSevr(i) := dout((i*2)+457 downto (i*2)+456);
      end loop;

      return retVar;
   end function;

   function toSlv (msg : MsgType) return slv is
      variable retVar : slv(RX_MSG_FIFO_WIDTH_C-1 downto 0);
      variable i      : natural;
   begin
      -- Reset the variables
      retVar := (others => '0');

      -- Load the BSA Data
      for i in 11 downto 0 loop
         retVar((i*32)+31 downto (i*32)) := msg.bsaQuantity(i);
      end loop;

      -- Load the time stamp
      retVar(447 downto 384) := msg.timeStamp;

      -- Load the MPS permit
      for i in 3 downto 0 loop
         retVar((i*2)+449 downto (i*2)+448) := msg.mpsPermit(i);
      end loop;

      -- Load the BSA Severity
      for i in 11 downto 0 loop
         retVar((i*2)+457 downto (i*2)+456) := msg.bsaSevr(i);
      end loop;

      return retVar;
   end function;

end package body BsaMpsMsgRxFramerPkg;
