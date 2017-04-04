-------------------------------------------------------------------------------
-- File       : Application.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-13
-- Last update: 2017-04-04
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
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
      timingRefClk         : in  sl;
      timingPhyClk         : in  sl;
      timingPhyRst         : in  sl;
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

   signal fifoRd    : slv(1 downto 0);
   signal fifoValid : slv(1 downto 0);
   signal remoteMsg : MsgArray(1 downto 0);

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

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
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

   --------------------
   -- BSA/MPS Receivers
   --------------------
   GEN_VEC : for i in 1 downto 0 generate
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
            fifoRd          => fifoRd(i),
            fifoValid       => fifoValid(i),
            remoteMsg       => remoteMsg(i),
            -- Remote LLRF BSA/MPS Ports
            refClk          => timingRefClk,
            gtRxP           => gtRxP(i),
            gtRxN           => gtRxN(i),
            gtTxP           => gtTxP(i),
            gtTxN           => gtTxN(i));
   end generate GEN_VEC;

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
         fifoRd          => fifoRd,
         fifoValid       => fifoValid,
         remoteMsg       => remoteMsg,
         -- Timing Interface
         timingBus       => timingBus,
         -- Diagnostic Interface
         diagnosticBus   => diagnosticBus);

end mapping;
