-------------------------------------------------------------------------------
-- File       : BsaMpsMsgRxCombineTb.vhd
-- Company    : SLAC National Accelerator Laboratory
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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library lcls2_llrf_bsa_mps_tx_core;
use lcls2_llrf_bsa_mps_tx_core.BsaMpsMsgRxFramerPkg.all;

entity BsaMpsMsgRxCombineTb is end BsaMpsMsgRxCombineTb;

architecture testbed of BsaMpsMsgRxCombineTb is

   constant CLK_PERIOD_C : time    := 5.384 ns;
   constant TPD_G        : time    := CLK_PERIOD_C/4;
   constant TIMEOUT_C    : natural := 185;  -- ~ 1MHz strobe    

   type RegType is record
      localTiming  : TimingBusType;
      remoteTiming : TimingBusType;
      timer        : natural range 0 to TIMEOUT_C;
   end record RegType;
   constant REG_INIT_C : RegType := (
      localTiming  => TIMING_BUS_INIT_C,
      remoteTiming => TIMING_BUS_INIT_C,
      timer        => 0);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal clk : sl := '0';
   signal rst : sl := '0';

   signal linkP : slv(1 downto 0) := (others => '0');
   signal linkN : slv(1 downto 0) := (others => '1');

   signal txData  : slv(15 downto 0) := (others => '0');
   signal txDataK : slv(1 downto 0)  := (others => '0');

   signal remoteRd    : slv(1 downto 0)      := (others => '0');
   signal remoteValid : slv(1 downto 0)      := (others => '0');
   signal remoteMsg   : MsgArray(1 downto 0) := (others => MSG_INIT_C);

   signal diagnosticBus : DiagnosticBusType := DIAGNOSTIC_BUS_INIT_C;

begin

   U_ClkRst : entity surf.ClkRst
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
      v.localTiming.strobe  := '0';
      v.remoteTiming.strobe := '0';

      -- Set valid timing link
      v.localTiming.valid      := '1';
      v.remoteTiming.valid     := '1';
      v.localTiming.v2.linkUp  := '1';
      v.remoteTiming.v2.linkUp := '1';

      -- Check the timer
      if (r.timer = TIMEOUT_C) then
         -- Reset the counter
         v.timer                          := 0;
         -- Increment the counter
         v.localTiming.message.timeStamp  := r.localTiming.message.timeStamp + 1;
         v.remoteTiming.message.timeStamp := r.remoteTiming.message.timeStamp + 1;
         -- Set the flag
         v.localTiming.strobe             := '1';
         v.remoteTiming.strobe            := '1';
      else
         -- Increment the counter
         v.timer := r.timer +1;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      -- -- Remote ahead of local
      -- v.localTiming.message.timeStamp  := toSlv(8, 64);  -- Added misalignment offsets to check BsaMpsMsgRxCombine's recovery function
      -- v.remoteTiming.message.timeStamp := toSlv(16, 64);  -- Added misalignment offsets to check BsaMpsMsgRxCombine's recovery function         
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

   ---------------------
   -- TX Frame Generator
   ---------------------
   U_Tx : entity lcls2_llrf_bsa_mps_tx_core.BsaMpsMsgTxFramer
      generic map (
         TPD_G => TPD_G)
      port map (
         -- BSA/MPS Interface (usrClk domain)
         usrClk       => clk,
         usrRst       => rst,
         timingStrobe => r.remoteTiming.strobe,
         timeStamp    => r.remoteTiming.message.timeStamp,
         userValue    => (others => '0'),
         bsaQuantity  => (others => (others => '0')),
         bsaSevr      => (others => (others => '0')),
         mpsPermit    => r.remoteTiming.message.timeStamp(3 downto 0),
         -- TX Data Interface (txClk domain)
         txClk        => clk,
         txRst        => rst,
         txData       => txData,
         txDataK      => txDataK);

   --------------------
   -- BSA/MPS Receivers
   --------------------
   GEN_VEC : for i in 1 downto 0 generate
      U_BsaMpsMsgRx : entity work.BsaMpsMsgRxCore
         generic map (
            TPD_G        => TPD_G,
            SIMULATION_G => true)
         port map (
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => clk,
            axilRst         => rst,
            axilReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
            axilReadSlave   => open,
            axilWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
            axilWriteSlave  => open,
            -- RX Frame Interface (axilClk domain)     
            remoteRd        => remoteRd(i),
            remoteValid     => remoteValid(i),
            remoteMsg       => remoteMsg(i),
            -- EMU TX Data Interface (txClk domain)
            txClk           => clk,
            txRst           => rst,
            txData          => txData,
            txDataK         => txDataK,
            -- Remote LLRF BSA/MPS Ports
            rxClk           => clk,
            rxRst           => rst,
            gtRefClk        => clk,
            gtRxP           => linkP(i),
            gtRxN           => linkN(i),
            gtTxP           => linkP(i),
            gtTxN           => linkN(i));
   end generate GEN_VEC;

   ------------------------------
   -- Message Concentrator Module
   ------------------------------
   U_Combine : entity work.BsaMpsMsgRxCombine
      generic map (
         TPD_G        => TPD_G,
         SIMULATION_G => true)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => clk,
         axilRst         => rst,
         axilReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
         axilReadSlave   => open,
         axilWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
         axilWriteSlave  => open,
         -- RX Frame Interface
         remoteRd        => remoteRd,
         remoteValid     => remoteValid,
         remoteMsg       => remoteMsg,
         -- Timing Interface
         timingBus       => r.localTiming,
         -- Diagnostic Interface
         diagnosticBus   => diagnosticBus);

end testbed;
