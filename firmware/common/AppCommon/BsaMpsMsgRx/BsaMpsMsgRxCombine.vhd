-------------------------------------------------------------------------------
-- File       : BsaMpsMsgRxCombine.vhd
-- Company    : SLAC National Accelerator Laboratory
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

entity BsaMpsMsgRxCombine is
   generic (
      TPD_G        : time    := 1 ns;
      SIMULATION_G : boolean := false);
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- RX Frame Interface
      remoteRd        : out slv(3 downto 0);
      remoteLinkUp    : in  slv(3 downto 0);
      remoteValid     : in  slv(3 downto 0);
      remoteMsg       : in  MsgArray(3 downto 0);
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
      dropCnt        : Slv32Array(3 downto 0);
      fifoRd         : sl;
      aligned        : slv(3 downto 0);
      sevr           : Slv2Array(3 downto 0);
      timeStampDebug : Slv64Array(4 downto 0);
      remoteRd       : slv(3 downto 0);
      diagnosticBus  : DiagnosticBusType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      state          : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      cntRst         => '0',
      dropCnt        => (others => (others => '0')),
      fifoRd         => '0',
      aligned        => (others => '0'),
      sevr           => (others => "11"),
      timeStampDebug => (others => (others => '0')),
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

   U_Fifo : entity surf.FifoSync
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "distributed",
         FWFT_EN_G     => true,
         DATA_WIDTH_G  => TIMING_MESSAGE_BITS_C,
         ADDR_WIDTH_G  => 4,            -- 2^4 = 16 samples
         FULL_THRES_G  => 8)            -- 8 sample threshold
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
                   packetRate, progFull, r, remoteLinkUp, remoteMsg,
                   remoteValid, timingMessage) is
      variable v         : RegType;
      variable axilEp    : AxiLiteEndPointType;
      variable busy      : sl;
      variable alignment : slv(3 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      alignment              := (others => '0');
      v.remoteRd             := (others => '0');
      v.fifoRd               := '0';
      v.diagnosticBus.strobe := '0';
      v.cntRst               := '0';

      -- do not add/average (static)
      v.diagnosticBus.fixed := (others => '1');

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

               -- Check the local FIFO threshold or no links
               if (progFull = '1') or (remoteLinkUp = 0) then
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
            for i in 3 downto 0 loop

               -- Check if behind in time with respect to local FIFO or no link
               if ((remoteMsg(i).timeStamp < timingMessage.timeStamp) and (remoteValid(i) = '1')) or (remoteLinkUp(i) = '0') then
                  -- Blow off data
                  v.remoteRd(i) := '1';
                  alignment(i)  := not(remoteLinkUp(i));
               else

                  -- Check if aligned with respect to local FIFO
                  if (remoteMsg(i).timeStamp = timingMessage.timeStamp) and (remoteValid(i) = '1') then
                     -- Set the flags
                     v.aligned(i) := '1';
                     v.sevr(i)    := "00";
                     alignment(i) := '1';
                  end if;

                  -- Check if ahead in time with respect to local FIFO
                  if (remoteMsg(i).timeStamp > timingMessage.timeStamp) and (remoteValid(i) = '1') then
                     -- Set the flag
                     alignment(i) := '1';
                  end if;

               end if;

               -- Keep a copy for debugging
               if (remoteValid(i) = '1') then
                  v.timeStampDebug(i) := remoteMsg(i).timeStamp;
               end if;

            end loop;

            -- Keep a copy for debugging
            v.timeStampDebug(4) := timingMessage.timeStamp;

            -- Check if ready to send BSA message
            if (progFull = '1') or (alignment = "1111") then
               -- Next state
               v.state := SEND_MSG_S;

            -- Return to IDLE
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

            -- Zero out the word
            v.diagnosticBus.sevr(30) := b"00";
            v.diagnosticBus.data(30) := x"0000_0000";

            -- Loop through the remote channels
            for i in 3 downto 0 loop

               -- Update the MPS message
               v.diagnosticBus.sevr(30) := r.sevr(i) or v.diagnosticBus.sevr(30);
               if (r.sevr(i) = "00") then
                  for j in 3 downto 0 loop
                     v.diagnosticBus.data(30)((8*i)+(2*j)+1 downto (8*i)+(2*j)) := remoteMsg(i).mpsPermit(j);
                  end loop;
               end if;

               -- Check for drop due to misalignment
               if (r.aligned(i) = '0') then
                  -- Increment the counter
                  v.dropCnt(i) := r.dropCnt(i) + 1;
               end if;

            end loop;

            ---------------------------------------------------------------------------------------
            -- Index |    sevr[1]      |    sevr[0]      |     data[31:16]    |     data[15:00]
            ---------------------------------------------------------------------------------------
            --    0  | Link[0].Q[1][0] | Link[0].I[1][0] | Link[0].Q[1][31:16]| Link[0].I[1][31:16]
            ---------------------------------------------------------------------------------------
            --    1  | Link[0].Q[2][0] | Link[0].I[2][0] | Link[0].Q[2][31:16]| Link[0].I[2][31:16]
            ---------------------------------------------------------------------------------------
            --    2  | Link[0].Q[3][0] | Link[0].I[3][0] | Link[0].Q[3][31:16]| Link[0].I[3][31:16]
            ---------------------------------------------------------------------------------------
            --    3  | Link[0].Q[4][0] | Link[0].I[4][0] | Link[0].Q[4][31:16]| Link[0].I[4][31:16]
            ---------------------------------------------------------------------------------------
            --    4  | Link[0].Q[5][0] | Link[0].I[5][0] | Link[0].Q[5][31:16]| Link[0].I[5][31:16] - Spare (not used)
            ---------------------------------------------------------------------------------------
            --    5  | Link[0].Q[6][0] | Link[0].I[6][0] | Link[0].Q[6][31:16]| Link[0].I[6][31:16] - Spare (not used)
            ---------------------------------------------------------------------------------------
            --    6  | Link[1].Q[1][0] | Link[1].I[1][0] | Link[1].Q[1][31:16]| Link[1].I[1][31:16]
            ---------------------------------------------------------------------------------------
            --    7  | Link[1].Q[2][0] | Link[1].I[2][0] | Link[1].Q[2][31:16]| Link[1].I[2][31:16]
            ---------------------------------------------------------------------------------------
            --    8  | Link[1].Q[3][0] | Link[1].I[3][0] | Link[1].Q[3][31:16]| Link[1].I[3][31:16]
            ---------------------------------------------------------------------------------------
            --    9  | Link[1].Q[4][0] | Link[1].I[4][0] | Link[1].Q[4][31:16]| Link[1].I[4][31:16]
            ---------------------------------------------------------------------------------------
            --   10  | Link[1].Q[5][0] | Link[1].I[5][0] | Link[1].Q[5][31:16]| Link[1].I[5][31:16] - Spare (not used)
            ---------------------------------------------------------------------------------------
            --   11  | Link[1].Q[6][0] | Link[1].I[6][0] | Link[1].Q[6][31:16]| Link[1].I[6][31:16] - Spare (not used)
            ---------------------------------------------------------------------------------------
            --   12  | Link[2].Q[1][0] | Link[2].I[1][0] | Link[2].Q[1][31:16]| Link[2].I[1][31:16]
            ---------------------------------------------------------------------------------------
            --   13  | Link[2].Q[2][0] | Link[2].I[2][0] | Link[2].Q[2][31:16]| Link[2].I[2][31:16]
            ---------------------------------------------------------------------------------------
            --   14  | Link[2].Q[3][0] | Link[2].I[3][0] | Link[2].Q[3][31:16]| Link[2].I[3][31:16]
            ---------------------------------------------------------------------------------------
            --   15  | Link[2].Q[4][0] | Link[2].I[4][0] | Link[2].Q[4][31:16]| Link[2].I[4][31:16]
            ---------------------------------------------------------------------------------------
            --   16  | Link[2].Q[5][0] | Link[2].I[5][0] | Link[2].Q[5][31:16]| Link[2].I[5][31:16] - Spare (not used)
            ---------------------------------------------------------------------------------------
            --   17  | Link[2].Q[6][0] | Link[2].I[6][0] | Link[2].Q[6][31:16]| Link[2].I[6][31:16] - Spare (not used)
            ---------------------------------------------------------------------------------------
            --   18  | Link[3].Q[1][0] | Link[3].I[1][0] | Link[3].Q[1][31:16]| Link[3].I[1][31:16]
            ---------------------------------------------------------------------------------------
            --   19  | Link[3].Q[2][0] | Link[3].I[2][0] | Link[3].Q[2][31:16]| Link[3].I[2][31:16]
            ---------------------------------------------------------------------------------------
            --   20  | Link[3].Q[3][0] | Link[3].I[3][0] | Link[3].Q[3][31:16]| Link[3].I[3][31:16]
            ---------------------------------------------------------------------------------------
            --   21  | Link[3].Q[4][0] | Link[3].I[4][0] | Link[3].Q[4][31:16]| Link[3].I[4][31:16]
            ---------------------------------------------------------------------------------------
            --   22  | Link[3].Q[5][0] | Link[3].I[5][0] | Link[3].Q[5][31:16]| Link[3].I[5][31:16] - Spare (not used)
            ---------------------------------------------------------------------------------------
            --   23  | Link[3].Q[6][0] | Link[3].I[6][0] | Link[3].Q[6][31:16]| Link[3].I[6][31:16] - Spare (not used)
            ---------------------------------------------------------------------------------------

            -- Update the data field
            for i in 3 downto 0 loop
               for j in 5 downto 0 loop

                  -- Link[i].I[j][0]
                  v.diagnosticBus.sevr(6*i+j)(0) := remoteMsg(i).bsaSevr(2*j+0)(0);  -- Only Mapping bsaSevr's LSB

                  -- Link[i].Q[j][0]
                  v.diagnosticBus.sevr(6*i+j)(1) := remoteMsg(i).bsaSevr(2*j+1)(0);  -- Only Mapping bsaSevr's LSB

                  -- Link[i].I[j][31:16]
                  v.diagnosticBus.data(6*i+j)(15 downto 0) := remoteMsg(i).bsaQuantity(2*j+0)(31 downto 16);  -- Only Mapping upper 16-bit from bsaQuantity

                  -- Link[i].Q[j][31:16]
                  v.diagnosticBus.data(6*i+j)(31 downto 16) := remoteMsg(i).bsaQuantity(2*j+1)(31 downto 16);  -- Only Mapping upper 16-bit from bsaQuantity

               end loop;
            end loop;

            -- Update the message field
            v.diagnosticBus.timingMessage := timingMessage;

            -- Next state
            v.state := IDLE_S;
      ----------------------------------------------------------------------
      end case;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      for i in 31 downto 0 loop
         axiSlaveRegisterR(axilEp, toSlv((0*128)+4*i, 12), 0, r.diagnosticBus.data(i));  -- 0x000:0x07F
         axiSlaveRegisterR(axilEp, toSlv((1*128)+4*i, 12), 0, r.diagnosticBus.sevr(i));  -- 0x080:0x0FF
      end loop;

      axiSlaveRegisterR(axilEp, x"100", 0, r.dropCnt(0));
      axiSlaveRegisterR(axilEp, x"110", 0, r.dropCnt(1));
      axiSlaveRegisterR(axilEp, x"120", 0, r.dropCnt(2));
      axiSlaveRegisterR(axilEp, x"130", 0, r.dropCnt(3));

      axiSlaveRegisterR(axilEp, x"200", 0, r.timeStampDebug(0));
      axiSlaveRegisterR(axilEp, x"210", 0, r.timeStampDebug(1));
      axiSlaveRegisterR(axilEp, x"220", 0, r.timeStampDebug(2));
      axiSlaveRegisterR(axilEp, x"230", 0, r.timeStampDebug(3));
      axiSlaveRegisterR(axilEp, x"240", 0, r.timeStampDebug(4));

      axiSlaveRegisterR(axilEp, x"300", 0, packetRate);

      axiSlaveRegister(axilEp, x"FFC", 0, v.cntRst);

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_SLVERR_C);

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

   U_packetRate : entity surf.SyncTrigRate
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
