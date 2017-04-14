-------------------------------------------------------------------------------
-- File       : ApplicationTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-13
-- Last update: 2017-04-14
-------------------------------------------------------------------------------
-- Description: BsaMpsMsgRxCombine Simulation Testbed
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
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.BsaMpsMsgRxFramerPkg.all;

library unisim;
use unisim.vcomponents.all;

entity ApplicationTb is end ApplicationTb;

architecture testbed of ApplicationTb is

   constant CLK_PERIOD_C : time    := 2.695 ns;
   constant TPD_G        : time    := 1 ns;
   constant TIMEOUT_C    : natural := 185;  -- ~ 1MHz strobe    

   type RegType is record
      timingBus : TimingBusType;
      timer     : natural range 0 to TIMEOUT_C;
   end record RegType;
   constant REG_INIT_C : RegType := (
      timingBus => TIMING_BUS_INIT_C,
      timer     => 0);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal clkP       : sl := '0';
   signal clkN       : sl := '1';
   signal rst        : sl := '0';
   signal refClk     : sl := '0';
   signal refClkDiv2 : sl := '0';
   signal clk        : sl := '0';

   signal loopbackP : slv(1 downto 0) := "00";
   signal loopbackN : slv(1 downto 0) := "11";

begin

   U_ClkRst : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clkP,
         clkN => clkN,
         rst  => rst);

   TIMING_REFCLK_IBUFDS_GTE3 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "01",  -- 2'b01: ODIV2 = Divide-by-2 version of O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => clkP,
         IB    => clkN,
         CEB   => '0',
         ODIV2 => refClkDiv2,
         O     => refClk);

   U_BUFG_GT_DIV2 : BUFG_GT
      port map (
         I       => refClkDiv2,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => clk);

   comb : process (r, rst) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.timingBus.strobe := '0';

      -- Set valid timing link
      v.timingBus.valid     := '1';
      v.timingBus.v2.linkUp := '1';

      -- Check the timer
      if (r.timer = TIMEOUT_C) then
         -- Reset the counter
         v.timer                       := 0;
         -- Increment the counter
         v.timingBus.message.timeStamp := r.timingBus.message.timeStamp + 1;
         -- Set the flag
         v.timingBus.strobe            := '1';
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

   U_App : entity work.Application
      generic map (
         TPD_G        => TPD_G,
         SIMULATION_G => false)
      port map (
         ----------------------
         -- Top Level Interface
         ----------------------
         -- AXI-Lite Interface (axilClk domain)
         axilClk              => clk,
         axilRst              => rst,
         axilReadMaster       => AXI_LITE_READ_MASTER_INIT_C,
         axilReadSlave        => open,
         axilWriteMaster      => AXI_LITE_WRITE_MASTER_INIT_C,
         axilWriteSlave       => open,
         -- Timing Interface (timingClk domain) 
         timingClk            => open,
         timingRst            => open,
         timingBus            => r.timingBus,
         timingPhy            => open,
         timingPhyClk         => clk,
         timingPhyRst         => rst,
         timingRefClk         => refClk,
         timingRefClkDiv2     => clk,
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk        => open,
         diagnosticRst        => open,
         diagnosticBus        => open,
         -- Waveform interface (waveformClk domain)
         waveformClk          => clk,
         waveformRst          => rst,
         obAppWaveformMasters => open,
         obAppWaveformSlaves  => WAVEFORM_SLAVE_ARRAY_INIT_C,
         ibAppWaveformMasters => WAVEFORM_MASTER_ARRAY_INIT_C,
         ibAppWaveformSlaves  => open,
         -- Backplane Messaging Interface  (axilClk domain)
         obBpMsgClientMaster  => open,
         obBpMsgClientSlave   => AXI_STREAM_SLAVE_FORCE_C,
         ibBpMsgClientMaster  => AXI_STREAM_MASTER_INIT_C,
         ibBpMsgClientSlave   => open,
         obBpMsgServerMaster  => open,
         obBpMsgServerSlave   => AXI_STREAM_SLAVE_FORCE_C,
         ibBpMsgServerMaster  => AXI_STREAM_MASTER_INIT_C,
         ibBpMsgServerSlave   => open,
         -- Application Debug Interface (axilClk domain)
         obAppDebugMaster     => open,
         obAppDebugSlave      => AXI_STREAM_SLAVE_FORCE_C,
         ibAppDebugMaster     => AXI_STREAM_MASTER_INIT_C,
         ibAppDebugSlave      => open,
         -- MPS Concentrator Interface (axilClk domain)
         mpsObMasters         => (others => AXI_STREAM_MASTER_INIT_C),
         mpsObSlaves          => open,
         -- Reference Clocks and Resets
         recTimingClk         => clk,
         recTimingRst         => rst,
         gthFabClk            => '0',
         -- Misc. Interface (axilClk domain)
         ipmiBsi              => BSI_BUS_INIT_C,
         ethPhyReady          => '1',
         -----------------------
         -- Application Ports --
         -----------------------
         -- AMC's JESD Ports
         gtRxP                => loopbackP,
         gtRxN                => loopbackN,
         gtTxP                => loopbackP,
         gtTxN                => loopbackN);

end testbed;
