-------------------------------------------------------------------------------
-- File       : BsaMpsMsgRxFramerReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-13
-- Last update: 2017-04-05
-------------------------------------------------------------------------------
-- Description: RX Data Framer's register module
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

entity BsaMpsMsgRxFramerReg is
   generic (
      TPD_G            : time            := 1 ns;
      SIMULATION_G     : boolean         := false;
      AXI_CLK_FREQ_G   : real            := 156.25E+6;  -- units of Hz
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Status/Configuration Interface (rxClk domain)
      rxClk           : in  sl;
      rxRst           : in  sl;
      rxLinkUp        : in  sl;
      rxDecErr        : in  slv(1 downto 0);
      rxDispErr       : in  slv(1 downto 0);
      rxBufStatus     : in  slv(2 downto 0);
      cPllLock        : in  sl;
      rxPolarity      : out sl;
      txPolarity      : out sl;
      loopback        : out sl;
      fifoWr          : in  sl;
      overflow        : in  sl;
      errPktLen       : in  sl;
      errCrc          : in  sl;
      sofDet          : in  sl;
      gtRst           : out sl;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end BsaMpsMsgRxFramerReg;

architecture rtl of BsaMpsMsgRxFramerReg is

   constant STATUS_SIZE_C : positive := 10;

   type RegType is record
      gtRst          : sl;
      rxPolarity     : sl;
      txPolarity     : sl;
      loopback       : sl;
      cntRst         : sl;
      rollOverEn     : slv(STATUS_SIZE_C-1 downto 0);
      hardRst        : sl;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      gtRst          => '0',
      rxPolarity     => '0',
      txPolarity     => '0',
      loopback       => '0',
      cntRst         => '1',
      rollOverEn     => toSlv(1, STATUS_SIZE_C),
      hardRst        => '0',
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


   signal statusOut       : slv(STATUS_SIZE_C-1 downto 0);
   signal statusCnt       : SlVectorArray(STATUS_SIZE_C-1 downto 0, 31 downto 0);
   signal rxBufStatusSync : slv(2 downto 0);
   signal pktLength       : slv(7 downto 0);
   signal packetRate      : slv(31 downto 0);
   signal sofRate         : slv(31 downto 0);
   signal gtRxFifoErr     : sl;

   -- attribute dont_touch      : string;
   -- attribute dont_touch of r : signal is "TRUE";

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, packetRate, r,
                   rxBufStatusSync, sofRate, statusCnt, statusOut) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.hardRst := '0';
      v.cntRst  := '0';
      v.gtRst   := '0';

      -- Check for hard reset
      if (r.hardRst = '1') then
         -- Reset the register
         v := REG_INIT_C;
      end if;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      for i in STATUS_SIZE_C-1 downto 0 loop
         axiSlaveRegisterR(axilEp, toSlv((4*i), 12), 0, muxSlVectorArray(statusCnt, i));
      end loop;
      axiSlaveRegisterR(axilEp, x"400", 0, statusOut);
      axiSlaveRegisterR(axilEp, x"404", 0, rxBufStatusSync);
      axiSlaveRegisterR(axilEp, x"410", 0, packetRate);
      axiSlaveRegisterR(axilEp, x"414", 0, sofRate);

      -- Map the write registers
      axiSlaveRegister(axilEp, x"700", 0, v.rxPolarity);
      axiSlaveRegister(axilEp, x"704", 0, v.txPolarity);
      axiSlaveRegister(axilEp, x"708", 0, v.loopback);

      axiSlaveRegister(axilEp, x"7F0", 0, v.rollOverEn);
      axiSlaveRegister(axilEp, x"7F4", 0, v.cntRst);
      axiSlaveRegister(axilEp, x"7F8", 0, v.gtRst);
      axiSlaveRegister(axilEp, x"7FC", 0, v.hardRst);

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_gtRst : entity work.PwrUpRst
      generic map (
         TPD_G      => TPD_G,
         DURATION_G => ite(SIMULATION_G, 250, 25000000))  -- 100 ms
      port map (
         arst   => r.gtRst,
         clk    => rxClk,
         rstOut => gtRst);

   U_packetRate : entity work.SyncTrigRate
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => false,
         REF_CLK_FREQ_G => AXI_CLK_FREQ_G,  -- units of Hz
         REFRESH_RATE_G => 1.0,             -- units of Hz
         CNT_WIDTH_G    => 32)              -- Counters' width
      port map (
         -- Trigger Input (locClk domain)
         trigIn      => fifoWr,
         -- Trigger Rate Output (locClk domain)
         trigRateOut => packetRate,
         -- Clocks
         locClk      => rxClk,
         refClk      => axilClk);

   U_sofRate : entity work.SyncTrigRate
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => false,
         REF_CLK_FREQ_G => AXI_CLK_FREQ_G,  -- units of Hz
         REFRESH_RATE_G => 1.0,             -- units of Hz
         CNT_WIDTH_G    => 32)              -- Counters' width
      port map (
         -- Trigger Input (locClk domain)
         trigIn      => sofDet,
         -- Trigger Rate Output (locClk domain)
         trigRateOut => sofRate,
         -- Clocks
         locClk      => rxClk,
         refClk      => axilClk);

   U_rxBufStatus : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 3)
      port map (
         wr_clk => rxClk,
         din    => rxBufStatus,
         rd_clk => axilClk,
         dout   => rxBufStatusSync);

   U_SyncOutVec : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 3)
      port map (
         clk        => rxClk,
         dataIn(0)  => r.rxPolarity,
         dataIn(1)  => r.txPolarity,
         dataIn(2)  => r.loopback,
         dataOut(0) => rxPolarity,
         dataOut(1) => txPolarity,
         dataOut(2) => loopback);

   gtRxFifoErr <= rxBufStatus(2) and rxLinkUp;

   U_SyncStatusVector : entity work.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '1',
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32,
         WIDTH_G        => STATUS_SIZE_C)
      port map (
         -- Input Status bit Signals (wrClk domain)
         statusIn(9)          => gtRxFifoErr,
         statusIn(8)          => cPllLock,
         statusIn(7)          => errCrc,
         statusIn(6)          => errPktLen,
         statusIn(5)          => overflow,
         statusIn(4 downto 3) => rxDispErr,
         statusIn(2 downto 1) => rxDecErr,
         statusIn(0)          => rxLinkUp,
         -- Output Status bit Signals (rdClk domain)  
         statusOut            => statusOut,
         -- Status Bit Counters Signals (rdClk domain) 
         cntRstIn             => r.cntRst,
         rollOverEnIn         => r.rollOverEn,
         cntOut               => statusCnt,
         -- Clocks and Reset Ports
         wrClk                => rxClk,
         rdClk                => axilClk);

end rtl;
