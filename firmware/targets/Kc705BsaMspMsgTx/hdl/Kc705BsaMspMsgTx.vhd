-------------------------------------------------------------------------------
-- File       : Kc705BsaMspMsgTx.vhd
-- Company    : SLAC National Accelerator Laboratory
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;

library lcls2_llrf_bsa_mps_tx_core;

library unisim;
use unisim.vcomponents.all;

entity Kc705BsaMspMsgTx is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      -- LEDs and Reset button
      extRst     : in  sl;
      led        : out slv(7 downto 0);
      -- GT Pins
      stableClkP : in  sl;              -- SGMII RefClk = 125 MHz
      stableClkN : in  sl;              -- SGMII RefClk = 125 MHz
      gtClkP     : in  sl;              -- GTX SMA clock = 371.428571
      gtClkN     : in  sl;              -- GTX SMA clock = 371.428571
      gtRxP      : in  sl;
      gtRxN      : in  sl;
      gtTxP      : out sl;
      gtTxN      : out sl);
end Kc705BsaMspMsgTx;

architecture top_level of Kc705BsaMspMsgTx is

   constant TIMEOUT_C : natural := 185;  -- ~ 1MHz strobe 

   type RegType is record
      timer  : natural range 0 to TIMEOUT_C;
      strobe : sl;
      cnt    : slv(127 downto 0);
   end record RegType;
   constant REG_INIT_C : RegType := (
      timer  => 0,
      strobe => '0',
      cnt    => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal refClk    : slv(1 downto 0);
   signal usrClk    : sl;
   signal usrRst    : sl;
   signal stableClk : sl;
   signal stableRst : sl;
   signal cPllLock  : sl;

   signal timingStrobe  : sl;
   signal timeStamp     : slv(63 downto 0);
   signal userValue     : slv(127 downto 0);
   signal bsaQuantity0  : slv(31 downto 0);
   signal bsaQuantity1  : slv(31 downto 0);
   signal bsaQuantity2  : slv(31 downto 0);
   signal bsaQuantity3  : slv(31 downto 0);
   signal bsaQuantity4  : slv(31 downto 0);
   signal bsaQuantity5  : slv(31 downto 0);
   signal bsaQuantity6  : slv(31 downto 0);
   signal bsaQuantity7  : slv(31 downto 0);
   signal bsaQuantity8  : slv(31 downto 0);
   signal bsaQuantity9  : slv(31 downto 0);
   signal bsaQuantity10 : slv(31 downto 0);
   signal bsaQuantity11 : slv(31 downto 0);
   signal bsaSevr0      : slv(1 downto 0);
   signal bsaSevr1      : slv(1 downto 0);
   signal bsaSevr2      : slv(1 downto 0);
   signal bsaSevr3      : slv(1 downto 0);
   signal bsaSevr4      : slv(1 downto 0);
   signal bsaSevr5      : slv(1 downto 0);
   signal bsaSevr6      : slv(1 downto 0);
   signal bsaSevr7      : slv(1 downto 0);
   signal bsaSevr8      : slv(1 downto 0);
   signal bsaSevr9      : slv(1 downto 0);
   signal bsaSevr10     : slv(1 downto 0);
   signal bsaSevr11     : slv(1 downto 0);
   signal mpsPermit     : slv(3 downto 0);

begin

   led(7) <= '0';
   led(6) <= '0';
   led(5) <= '0';
   led(4) <= '0';
   led(3) <= '1';
   led(2) <= cPllLock;
   led(1) <= cPllLock;
   led(0) <= cPllLock;

   U_IBUFDS0 : IBUFDS_GTE2
      port map (
         I     => gtClkP,               -- GTX SMA clock = 371.428571
         IB    => gtClkN,               -- GTX SMA clock = 371.428571
         CEB   => '0',
         ODIV2 => refClk(0),            -- 185.714 MHz
         O     => open);

   U_BUFG0 : BUFG
      port map (
         I => refClk(0),
         O => usrClk);

   U_RstSync0 : entity surf.RstSync
      generic map(
         TPD_G => TPD_G)
      port map (
         clk      => usrClk,
         asyncRst => extRst,
         syncRst  => usrRst);

   U_IBUFDS1 : IBUFDS_GTE2
      port map (
         I     => stableClkP,           -- SGMII RefClk = 125 MHz
         IB    => stableClkN,           -- SGMII RefClk = 125 MHz
         CEB   => '0',
         ODIV2 => refClk(1),            -- 62.5 MHz
         O     => open);

   U_BUFG1 : BUFG
      port map (
         I => refClk(1),
         O => stableClk);

   U_RstSync1 : entity surf.RstSync
      generic map(
         TPD_G => TPD_G)
      port map (
         clk      => stableClk,
         asyncRst => extRst,
         syncRst  => stableRst);

   U_Core : entity lcls2_llrf_bsa_mps_tx_core.BsaMspMsgTxCore
      generic map(
         TPD_G => TPD_G)
      port map (
         -- BSA/MPS Interface
         usrClk        => usrClk,
         usrRst        => usrRst,
         timingStrobe  => timingStrobe,
         timeStamp     => timeStamp,
         userValue     => userValue,
         bsaQuantity0  => bsaQuantity0,
         bsaQuantity1  => bsaQuantity1,
         bsaQuantity2  => bsaQuantity2,
         bsaQuantity3  => bsaQuantity3,
         bsaQuantity4  => bsaQuantity4,
         bsaQuantity5  => bsaQuantity5,
         bsaQuantity6  => bsaQuantity6,
         bsaQuantity7  => bsaQuantity7,
         bsaQuantity8  => bsaQuantity8,
         bsaQuantity9  => bsaQuantity9,
         bsaQuantity10 => bsaQuantity10,
         bsaQuantity11 => bsaQuantity11,
         bsaSevr0      => bsaSevr0,
         bsaSevr1      => bsaSevr1,
         bsaSevr2      => bsaSevr2,
         bsaSevr3      => bsaSevr3,
         bsaSevr4      => bsaSevr4,
         bsaSevr5      => bsaSevr5,
         bsaSevr6      => bsaSevr6,
         bsaSevr7      => bsaSevr7,
         bsaSevr8      => bsaSevr8,
         bsaSevr9      => bsaSevr9,
         bsaSevr10     => bsaSevr10,
         bsaSevr11     => bsaSevr11,
         mpsPermit     => mpsPermit,
         -- GTX's Clock and Reset
         cPllRefClk    => refClk(0),    -- 185.714 MHz
         stableClk     => stableClk,  -- Note: REQP-1584 = GTxE2 PLLLOCKDETCLK can not be REFCLK (cPllRefClk != stableClk)
         stableRst     => stableRst,
         -- GTX Status/Config Interface   
         cPllLock      => cPllLock,
         txPreCursor   => (others => '0'),
         txPostCursor  => (others => '0'),
         txDiffCtrl    => "1111",
         -- GTX Ports
         gtTxP         => gtTxP,
         gtTxN         => gtTxN,
         gtRxP         => gtRxP,
         gtRxN         => gtRxN);

   comb : process (r, usrRst) is
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
      if (usrRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      timingStrobe  <= r.strobe;
      timeStamp     <= r.cnt(63 downto 0);
      userValue     <= r.cnt(127 downto 0);
      bsaQuantity0  <= r.cnt(31 downto 0);
      bsaQuantity1  <= r.cnt(31 downto 0);
      bsaQuantity2  <= r.cnt(31 downto 0);
      bsaQuantity3  <= r.cnt(31 downto 0);
      bsaQuantity4  <= r.cnt(31 downto 0);
      bsaQuantity5  <= r.cnt(31 downto 0);
      bsaQuantity6  <= r.cnt(31 downto 0);
      bsaQuantity7  <= r.cnt(31 downto 0);
      bsaQuantity8  <= r.cnt(31 downto 0);
      bsaQuantity9  <= r.cnt(31 downto 0);
      bsaQuantity10 <= r.cnt(31 downto 0);
      bsaQuantity11 <= r.cnt(31 downto 0);
      bsaSevr0      <= r.cnt(1 downto 0);
      bsaSevr1      <= r.cnt(1 downto 0);
      bsaSevr2      <= r.cnt(1 downto 0);
      bsaSevr3      <= r.cnt(1 downto 0);
      bsaSevr4      <= r.cnt(1 downto 0);
      bsaSevr5      <= r.cnt(1 downto 0);
      bsaSevr6      <= r.cnt(1 downto 0);
      bsaSevr7      <= r.cnt(1 downto 0);
      bsaSevr8      <= r.cnt(1 downto 0);
      bsaSevr9      <= r.cnt(1 downto 0);
      bsaSevr10     <= r.cnt(1 downto 0);
      bsaSevr11     <= r.cnt(1 downto 0);
      mpsPermit     <= r.cnt(3 downto 0);

   end process comb;

   seq : process (usrClk) is
   begin
      if rising_edge(usrClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end top_level;
