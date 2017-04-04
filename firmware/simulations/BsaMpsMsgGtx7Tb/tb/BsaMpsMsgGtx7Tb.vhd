-------------------------------------------------------------------------------
-- File       : BsaMpsMsgGtx7Tb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-13
-- Last update: 2017-04-04
-------------------------------------------------------------------------------
-- Description: GTX7 Wrapper Simulation Testbed
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.BsaMpsMsgRxFramerPkg.all;

entity BsaMpsMsgGtx7Tb is end BsaMpsMsgGtx7Tb;

architecture testbed of BsaMpsMsgGtx7Tb is

   constant CLK_PERIOD_C : time    := 5.384 ns;
   constant TPD_G        : time    := CLK_PERIOD_C/4;
   constant TIMEOUT_C    : natural := 185;  -- ~ 1MHz strobe    

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

   signal clk : sl := '0';
   signal rst : sl := '0';

   signal linkP : sl := '0';
   signal linkN : sl := '1';

   signal rxValid   : sl               := '0';
   signal rxData    : slv(15 downto 0) := (others => '0');
   signal rxdataK   : slv(1 downto 0)  := (others => '0');
   signal rxDecErr  : slv(1 downto 0)  := (others => '0');
   signal rxDispErr : slv(1 downto 0)  := (others => '0');

   signal fifoValid : sl       := '0';
   signal remoteMsg : MsgType := MSG_INIT_C;

begin

   U_ClkRst : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk,
         rst  => rst);

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

   U_Tx : entity work.BsaMspMsgTxCore
      generic map (
         TPD_G                 => TPD_G,
         SIM_GTRESET_SPEEDUP_G => "TRUE",
         SIMULATION_G          => true)
      port map (
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
         cPllRefClk    => clk,
         stableClk     => clk,
         stableRst     => rst,
         -- GTX Status/Config Interface   
         txPreCursor   => (others => '0'),
         txPostCursor  => (others => '0'),
         txDiffCtrl    => "1111",
         -- GTX Ports
         gtTxP         => linkP,
         gtTxN         => linkN,
         gtRxP         => '0',
         gtRxN         => '1');

   U_Rx : entity work.BsaMpsMsgRxGtx7
      generic map (
         TPD_G                 => TPD_G,
         SIM_GTRESET_SPEEDUP_G => "TRUE",
         SIMULATION_G          => true)
      port map (
         -- Clock and Reset
         cPllRefClk => clk,
         stableClk  => clk,
         stableRst  => rst,
         -- GTX Interface
         gtTxP      => open,
         gtTxN      => open,
         gtRxP      => linkP,
         gtRxN      => linkN,
         -- RX Interface
         rxClk      => clk,
         rxRst      => rst,
         rxValid    => rxValid,
         rxData     => rxData,
         rxdataK    => rxdataK,
         rxDecErr   => rxDecErr,
         rxDispErr  => rxDispErr);

   U_RxFramer : entity work.BsaMpsMsgRxFramer
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => true,
         AXI_CLK_FREQ_G   => 185.7E+6,  -- units of Hz
         AXI_ERROR_RESP_G => AXI_RESP_DECERR_C)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => clk,
         axilRst         => rst,
         axilReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
         axilReadSlave   => open,
         axilWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
         axilWriteSlave  => open,
         -- RX Data Interface (clk domain)
         rxClk           => clk,
         rxRst           => rst,
         rxValid         => rxValid,
         rxData          => rxData,
         rxdataK         => rxdataK,
         rxDecErr        => rxDecErr,
         rxDispErr       => rxDispErr,
         rxBufStatus     => "000",
         rxPolarity      => open,
         cPllLock        => '1',
         gtRst           => open,
         -- RX Frame Interface (axilClk domain)     
         fifoRd          => '1',
         fifoValid       => fifoValid,
         remoteMsg       => remoteMsg);

end testbed;
