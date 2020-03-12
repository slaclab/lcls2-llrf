-------------------------------------------------------------------------------
-- File       : Application.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Application Core's Top Level
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

use work.BsaMpsMsgRxFramerPkg.all;

entity Application is
   generic (
      TPD_G            : time             := 1 ns;
      SIMULATION_G     : boolean          := false;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := x"80000000";
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);
   port (
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (axilClk domain)
      axilClk              : in  sl;
      axilRst              : in  sl;
      axilReadMaster       : in  AxiLiteReadMasterType;
      axilReadSlave        : out AxiLiteReadSlaveType;
      axilWriteMaster      : in  AxiLiteWriteMasterType;
      axilWriteSlave       : out AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk            : out sl;
      timingRst            : out sl;
      timingBus            : in  TimingBusType;
      timingPhy            : out TimingPhyType;
      timingPhyClk         : in  sl;
      timingPhyRst         : in  sl;
      timingRefClk         : in  sl;
      timingRefClkDiv2     : in  sl;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : out sl;
      diagnosticRst        : out sl;
      diagnosticBus        : out DiagnosticBusType;
      -- Waveform interface (waveformClk domain)
      waveformClk          : in  sl;
      waveformRst          : in  sl;
      obAppWaveformMasters : out WaveformMasterArrayType;
      obAppWaveformSlaves  : in  WaveformSlaveArrayType;
      ibAppWaveformMasters : in  WaveformMasterArrayType;
      ibAppWaveformSlaves  : out WaveformSlaveArrayType;
      -- Backplane Messaging Interface  (axilClk domain)
      obBpMsgClientMaster  : out AxiStreamMasterType;
      obBpMsgClientSlave   : in  AxiStreamSlaveType;
      ibBpMsgClientMaster  : in  AxiStreamMasterType;
      ibBpMsgClientSlave   : out AxiStreamSlaveType;
      obBpMsgServerMaster  : out AxiStreamMasterType;
      obBpMsgServerSlave   : in  AxiStreamSlaveType;
      ibBpMsgServerMaster  : in  AxiStreamMasterType;
      ibBpMsgServerSlave   : out AxiStreamSlaveType;
      -- Application Debug Interface (axilClk domain)
      obAppDebugMaster     : out AxiStreamMasterType;
      obAppDebugSlave      : in  AxiStreamSlaveType;
      ibAppDebugMaster     : in  AxiStreamMasterType;
      ibAppDebugSlave      : out AxiStreamSlaveType;
      -- MPS Concentrator Interface (axilClk domain)
      mpsObMasters         : in  AxiStreamMasterArray(14 downto 0);
      mpsObSlaves          : out AxiStreamSlaveArray(14 downto 0);
      -- Reference Clocks and Resets
      recTimingClk         : in  sl;
      recTimingRst         : in  sl;
      gthFabClk            : in  sl;
      -- Misc. Interface (axilClk domain)
      ipmiBsi              : in  BsiBusType;
      ethPhyReady          : in  sl;
      -----------------------
      -- Application Ports --
      -----------------------
      -- Remote LLRF BSA/MPS Ports
      gtRxP                : in  slv(1 downto 0);
      gtRxN                : in  slv(1 downto 0);
      gtTxP                : out slv(1 downto 0);
      gtTxN                : out slv(1 downto 0));
end Application;

architecture mapping of Application is

   constant NUM_AXI_MASTERS_C : natural := 3;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 31, 28);

   constant RX0_INDEX_C     : natural := 0;
   constant RX1_INDEX_C     : natural := 1;
   constant COMBINE_INDEX_C : natural := 2;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal remoteRd     : slv(1 downto 0);
   signal remoteLinkUp : slv(1 downto 0);
   signal remoteValid  : slv(1 downto 0);
   signal remoteMsg    : MsgArray(1 downto 0);

   signal txData  : slv(15 downto 0);
   signal txDataK : slv(1 downto 0);

   signal clk : sl;
   signal rst : sl;

begin

   -- Waveform interface (unused)
   obAppWaveformMasters <= WAVEFORM_MASTER_ARRAY_INIT_C;
   ibAppWaveformSlaves  <= WAVEFORM_SLAVE_ARRAY_INIT_C;

   -- Backplane Messaging Interface (unused)
   obBpMsgClientMaster <= AXI_STREAM_MASTER_INIT_C;
   ibBpMsgClientSlave  <= AXI_STREAM_SLAVE_FORCE_C;
   obBpMsgServerMaster <= AXI_STREAM_MASTER_INIT_C;
   ibBpMsgServerSlave  <= AXI_STREAM_SLAVE_FORCE_C;

   -- Application Debug Interface (unused)
   obAppDebugMaster <= AXI_STREAM_MASTER_INIT_C;
   ibAppDebugSlave  <= AXI_STREAM_SLAVE_FORCE_C;

   -- MPS Concentrator Interface (unused)
   mpsObSlaves <= (others => AXI_STREAM_SLAVE_FORCE_C);

   -- Using the AXI-Lite clock for timing interface
   timingClk <= axilClk;
   timingRst <= axilRst;
   timingPhy <= TIMING_PHY_INIT_C;      -- Not a timing generator application

   -- Using the AXI-Lite clock for timing interface
   diagnosticClk <= axilClk;
   diagnosticRst <= axilRst;

   U_ClockManager : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => true,
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 1,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 5.355,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 6.000,
         CLKOUT0_DIVIDE_F_G => 6.000)
      port map(
         clkIn     => timingRefClkDiv2,
         rstIn     => axilRst,
         clkOut(0) => clk,
         rstOut(0) => rst);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);


   GEN_VEC : for i in 1 downto 0 generate

      --------------------
      -- BSA/MPS Receivers
      --------------------   
      U_BsaMpsMsgRx : entity work.BsaMpsMsgRxCore
         generic map (
            TPD_G            => TPD_G,
            SIMULATION_G     => SIMULATION_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i),
            -- RX Frame Interface (axilClk domain)     
            remoteRd        => remoteRd(i),
            remoteLinkUp    => remoteLinkUp(i),
            remoteValid     => remoteValid(i),
            remoteMsg       => remoteMsg(i),
            -- Emulation TX Data Interface (txClk domain)
            txClk           => clk,
            txRst           => rst,
            txData          => txData,
            txDataK         => txDataK,
            -- Remote LLRF BSA/MPS Ports
            rxClk           => clk,
            rxRst           => rst,
            gtRefClk        => timingRefClk,
            gtRxP           => gtRxP(i),
            gtRxN           => gtRxN(i),
            gtTxP           => gtTxP(i),
            gtTxN           => gtTxN(i));

   end generate GEN_VEC;

   -------------------------------------------------
   -- Emulation of TX Data (Used for debugging only)
   -------------------------------------------------
   U_EmuTx : entity lcls2_llrf_bsa_mps_tx_core.BsaMpsMsgTxFramer
      generic map (
         TPD_G => TPD_G)
      port map (
         -- BSA/MPS Interface (usrClk domain)
         usrClk       => axilClk,
         usrRst       => axilRst,
         timingStrobe => timingBus.strobe,
         timeStamp    => timingBus.message.timeStamp,
         userValue    => (others => '1'),
         bsaQuantity  => (others => (others => '0')),
         bsaSevr      => (others => (others => '0')),
         mpsPermit    => (others => '0'),
         -- TX Data Interface (txClk domain)
         txClk        => clk,
         txRst        => rst,
         txData       => txData,
         txDataK      => txDataK);

   ------------------------------
   -- Message Concentrator Module
   ------------------------------
   U_Combine : entity work.BsaMpsMsgRxCombine
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(COMBINE_INDEX_C),
         axilReadSlave   => axilReadSlaves(COMBINE_INDEX_C),
         axilWriteMaster => axilWriteMasters(COMBINE_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(COMBINE_INDEX_C),
         -- RX Frame Interface
         remoteRd        => remoteRd,
         remoteLinkUp    => remoteLinkUp,
         remoteValid     => remoteValid,
         remoteMsg       => remoteMsg,
         -- Timing Interface
         timingBus       => timingBus,
         -- Diagnostic Interface
         diagnosticBus   => diagnosticBus);

end mapping;
