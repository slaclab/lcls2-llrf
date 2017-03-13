-------------------------------------------------------------------------------
-- File       : Kc705BsaMspMsgTx.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-13
-- Last update: 2017-03-13
-------------------------------------------------------------------------------
-- Description: Development Board Example
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

use work.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Kc705BsaMspMsgTx is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      -- LEDs and Reset button
      extRst : in  sl;
      led    : out slv(7 downto 0);
      -- GT Pins
      gtClkP : in  sl;                  -- SMA clock = 371.428571
      gtClkN : in  sl;                  -- SMA clock = 371.428571
      gtRxP  : in  sl;
      gtRxN  : in  sl;
      gtTxP  : out sl;
      gtTxN  : out sl);
end Kc705BsaMspMsgTx;

architecture top_level of Kc705BsaMspMsgTx is

   constant TIMEOUT_C : natural := 185;

   type RegType is record
      timer  : natural range 0 to TIMEOUT_C;
      strobe : sl;
      cnt    : slv(63 downto 0);
   end record RegType;
   constant REG_INIT_C : RegType := (
      timer  => 0,
      strobe => '0',
      cnt    => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal refClk   : sl;
   signal clk      : sl;
   signal rst      : sl;
   signal cPllLock : sl;

begin

   led(7) <= '0';
   led(6) <= '0';
   led(5) <= '0';
   led(4) <= '0';
   led(3) <= '1';
   led(2) <= cPllLock;
   led(1) <= cPllLock;
   led(0) <= cPllLock;

   U_IBUFDS_GTE2 : IBUFDS_GTE2
      port map (
         I     => gtClkP,
         IB    => gtClkN,
         CEB   => '0',
         ODIV2 => refClk,               -- divide by two
         O     => open);

   U_BUFG : BUFG
      port map (
         I => refClk,
         O => clk);

   U_RstSync : entity work.RstSync
      generic map(
         TPD_G => TPD_G)
      port map (
         clk      => clk,
         asyncRst => extRst,
         syncRst  => rst);

   U_Core : entity work.BsaMspMsgTxCore
      generic map (
         -- BSA/MPS Interface
         usrClk        => clk,
         usrRst        => rst,
         timingStrobe  => r.strobe,
         timeStamp     => r.cnt,
         bsaQuantity0  => r.cnt(31 downto 0),
         bsaQuantity1  => r.cnt(31 downto 0),
         bsaQuantity2  => r.cnt(31 downto 0),
         bsaQuantity3  => r.cnt(31 downto 0),
         bsaQuantity4  => r.cnt(31 downto 0),
         bsaQuantity5  => r.cnt(31 downto 0),
         bsaQuantity6  => r.cnt(31 downto 0),
         bsaQuantity7  => r.cnt(31 downto 0),
         bsaQuantity8  => r.cnt(31 downto 0),
         bsaQuantity9  => r.cnt(31 downto 0),
         bsaQuantity10 => r.cnt(31 downto 0),
         bsaQuantity11 => r.cnt(31 downto 0),
         mpsPermit     => r.cnt(3 downto 0),
         -- GTX's Clock and Reset
         cPllRefClk    => refClk,
         stableClk     => clk,
         stableRst     => rst,
         -- GTX Status/Config Interface   
         cPllLock      => cPllLock,
         txPolarity    => '0',
         txPreCursor   => (others => '0'),
         txPostCursor  => (others => '0'),
         txDiffCtrl    => "1111",
         -- GTX Ports
         gtTxP         => gtTxP,
         gtTxN         => gtTxN,
         gtRxP         => gtRxP,
         gtRxN         => gtRxN);

   comb : process (r, rst) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.strobe := '0';

      -- Check the timer
      if (r.timer = TIMEOUT_C) then
         -- Reset the counter
         v.timer  := 0;
         -- Increment the counter
         v.cnt    := r.cnt + 1;
         -- Set the flag
         v.strobe := '1';
      else
         -- Increment the counter
         v.timer := r.timer +1;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end top_level;
