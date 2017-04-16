-------------------------------------------------------------------------------
-- File       : BsaMpsMsgRxCombine.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-13
-- Last update: 2017-04-15
-------------------------------------------------------------------------------
-- Description: Combines the timingBus with the two remote links to form the 
--              diagnosticBus message.
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
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.BsaMpsMsgRxFramerPkg.all;

entity BsaMpsMsgRxCombine is
   generic (
      TPD_G            : time            := 1 ns;
      SIMULATION_G     : boolean         := false;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_SLVERR_C);
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- RX Frame Interface 
      remoteRd        : out slv(1 downto 0);
      remoteValid     : in  slv(1 downto 0);
      remoteMsg       : in  MsgArray(1 downto 0);
      -- Timing Interface
      timingBus       : in  TimingBusType;
      -- Diagnostic Interface
      diagnosticBus   : out DiagnosticBusType);
end BsaMpsMsgRxCombine;

architecture rtl of BsaMpsMsgRxCombine is

   type StateType is (
      IDLE_S,
      CHECK_ALIGN_S,
      SEND_MSG_S);

   type RegType is record
      cntRst         : sl;
      dropCnt        : Slv32Array(1 downto 0);
      fifoRd         : sl;
      aligned        : slv(1 downto 0);
      sevr           : Slv2Array(1 downto 0);
      remoteRd       : slv(1 downto 0);
      diagnosticBus  : DiagnosticBusType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      state          : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      cntRst         => '0',
      dropCnt        => (others => x"0000_0000"),
      fifoRd         => '0',
      aligned        => (others => '0'),
      sevr           => (others => "11"),
      remoteRd       => (others => '0'),
      diagnosticBus  => DIAGNOSTIC_BUS_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      state          => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal fifoRst       : sl;
   signal fifoWr        : sl;
   signal fifoRd        : sl;
   signal fifoValid     : sl;
   signal progFull      : sl;
   signal fifoDin       : slv(TIMING_MESSAGE_BITS_C-1 downto 0);
   signal fifoDout      : slv(TIMING_MESSAGE_BITS_C-1 downto 0);
   signal packetRate    : slv(31 downto 0);
   signal timingMessage : TimingMessageType;

   attribute dont_touch                  : string;
   attribute dont_touch of r             : signal is "TRUE";
   attribute dont_touch of fifoRst       : signal is "TRUE";
   attribute dont_touch of fifoWr        : signal is "TRUE";
   attribute dont_touch of fifoRd        : signal is "TRUE";
   attribute dont_touch of fifoValid     : signal is "TRUE";
   attribute dont_touch of progFull      : signal is "TRUE";
   attribute dont_touch of timingMessage : signal is "TRUE";

begin

   U_Fifo : entity work.FifoSync
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         FWFT_EN_G    => true,
         DATA_WIDTH_G => TIMING_MESSAGE_BITS_C,
         ADDR_WIDTH_G => 5,             --32 samples
         FULL_THRES_G => 24)            -- 24 sample threshold
      port map (
         rst       => axilRst,
         clk       => axilClk,
         wr_en     => fifoWr,
         rd_en     => fifoRd,
         din       => fifoDin,
         dout      => fifoDout,
         valid     => fifoValid,
         prog_full => progFull);

   fifoWr        <= timingBus.strobe and timingBus.valid and timingBus.v2.linkUp;
   fifoDin       <= toSlv(timingBus.message);
   timingMessage <= toTimingMessageType(fifoDout);

   comb : process (axilReadMaster, axilRst, axilWriteMaster, fifoValid,
                   packetRate, progFull, r, remoteMsg, remoteValid,
                   timingMessage) is
      variable v           : RegType;
      variable axilEp      : AxiLiteEndPointType;
      variable busy        : sl;
      variable remoteAhead : slv(1 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      remoteAhead            := (others => '0');
      v.remoteRd             := (others => '0');
      v.fifoRd               := '0';
      v.diagnosticBus.strobe := '0';
      v.cntRst               := '0';

      -- Check if busy reading one of the FIFOs
      busy := uOr(r.remoteRd) or r.fifoRd or r.diagnosticBus.strobe;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Reset flags
            v.aligned := (others => '0');
            v.sevr    := (others => "11");
            -- Check if local FIFO has data and not busy
            if (fifoValid = '1') and (busy = '0') then
               -- Check the local FIFO threshold 
               if (progFull = '1') then
                  -- Next state
                  v.state := CHECK_ALIGN_S;
               -- Check if either of the remote FIFOs have data
               elsif (uOr(remoteValid) = '1') then
                  -- Next state
                  v.state := CHECK_ALIGN_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when CHECK_ALIGN_S =>
            -- Loop through the remote channels
            for i in 1 downto 0 loop
               -- Check if behind in time with respect to local FIFO
               if (remoteMsg(i).timeStamp < timingMessage.timeStamp) and (remoteValid(i) = '1') then
                  -- Blow off data
                  v.remoteRd(i) := '1';
               end if;
               -- Check if aligned with respect to local FIFO
               if (remoteMsg(i).timeStamp = timingMessage.timeStamp) and (remoteValid(i) = '1') then
                  -- Set the flags
                  v.aligned(i) := '1';
                  v.sevr(i)    := "00";
               end if;
               -- Check if ahead in time with respect to local FIFO
               if (remoteMsg(i).timeStamp > timingMessage.timeStamp) and (remoteValid(i) = '1') then
                  -- Set the flag
                  remoteAhead(i) := '1';
               end if;
            end loop;
            -- Check if both remote channels are aligned to local channel
            if (v.aligned = "11") then
               -- Next state
               v.state := SEND_MSG_S;
            -- Check if both remote channels are ahead of time
            elsif (remoteAhead = "11") then
               -- Next state
               v.state := SEND_MSG_S;
            -- Check if link0 aligned but link1 ahead
            elsif (v.aligned = "01") and (remoteAhead = "10") then
               -- Next state
               v.state := SEND_MSG_S;
            -- Check if link1 aligned but link0 ahead
            elsif (v.aligned = "10") and (remoteAhead = "01") then
               -- Next state
               v.state := SEND_MSG_S;
            elsif (progFull = '1') then
               -- Next state
               v.state := SEND_MSG_S;
            else
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when SEND_MSG_S =>
            -- Accept the data
            v.remoteRd             := r.aligned;
            v.fifoRd               := '1';
            v.diagnosticBus.strobe := '1';
            -- Update the data field
            for i in 11 downto 0 loop
               -- Link 0
               v.diagnosticBus.sevr(i+0)  := r.sevr(0);
               v.diagnosticBus.data(i+0)  := remoteMsg(0).bsaQuantity(i);
               -- Link 1
               v.diagnosticBus.sevr(i+12) := r.sevr(1);
               v.diagnosticBus.data(i+12) := remoteMsg(1).bsaQuantity(i);
            end loop;
            -- Link 0
            v.diagnosticBus.sevr(30)      := r.sevr(0);
            v.diagnosticBus.data(30)      := x"0000_000" & remoteMsg(0).mpsPermit;
            -- Link 1
            v.diagnosticBus.sevr(31)      := r.sevr(1);
            v.diagnosticBus.data(31)      := x"0000_000" & remoteMsg(1).mpsPermit;
            -- Update the message field
            v.diagnosticBus.timingMessage := timingMessage;
            -- Loop through the remote channels
            for i in 1 downto 0 loop
               -- Check for drop due to misalignment
               if (r.aligned(i) = '0') then
                  -- Increment the counter
                  v.dropCnt(i) := r.dropCnt(i) + 1;
               end if;
            end loop;
            -- Next state
            v.state := IDLE_S;
      ----------------------------------------------------------------------
      end case;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegisterR(axilEp, x"700", 0, r.dropCnt(0));
      axiSlaveRegisterR(axilEp, x"704", 0, r.dropCnt(1));
      axiSlaveRegisterR(axilEp, x"708", 0, packetRate);

      axiSlaveRegister(axilEp, x"FFC", 0, v.cntRst);

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Check for counter reset
      if (r.cntRst = '1') then
         -- Reset the counters
         v.dropCnt := (others => x"0000_0000");
      end if;

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      fifoRd         <= r.fifoRd;
      remoteRd       <= r.remoteRd;
      diagnosticBus  <= r.diagnosticBus;
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_packetRate : entity work.SyncTrigRate
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => false,
         REF_CLK_FREQ_G => 156.25E+6,   -- units of Hz
         REFRESH_RATE_G => 1.0,         -- units of Hz
         CNT_WIDTH_G    => 32)          -- Counters' width
      port map (
         -- Trigger Input (locClk domain)
         trigIn      => r.fifoRd,
         -- Trigger Rate Output (locClk domain)
         trigRateOut => packetRate,
         -- Clocks
         locClk      => axilClk,
         refClk      => axilClk);

end rtl;
