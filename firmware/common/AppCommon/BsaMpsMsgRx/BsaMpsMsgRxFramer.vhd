-------------------------------------------------------------------------------
-- File       : BsaMpsMsgRxFramer.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: RX Data Framer
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

entity BsaMpsMsgRxFramer is
   generic (
      TPD_G            : time            := 1 ns;
      SIMULATION_G     : boolean         := false;
      AXI_CLK_FREQ_G   : real            := 156.25E+6;  -- units of Hz
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- RX Data Interface (clk domain)
      rxClk           : in  sl;
      rxRst           : in  sl;
      rxValid         : in  sl;
      rxData          : in  slv(15 downto 0);
      rxdataK         : in  slv(1 downto 0);
      rxDecErr        : in  slv(1 downto 0);
      rxDispErr       : in  slv(1 downto 0);
      rxBufStatus     : in  slv(2 downto 0);
      rxPolarity      : out sl;
      txPolarity      : out sl;
      loopback        : out sl;
      cPllLock        : in  sl;
      gtRst           : out sl;
      -- RX Frame Interface (axilClk domain)     
      remoteRd        : in  sl;
      remoteValid     : out sl;
      remoteMsg       : out MsgType);
end BsaMpsMsgRxFramer;

architecture rtl of BsaMpsMsgRxFramer is

   constant K28_5_C : slv(7 downto 0)  := "10111100";  -- K28.5, 0xBC
   constant K28_1_C : slv(7 downto 0)  := "00111100";  -- K28.1, 0x3C
   constant K28_2_C : slv(7 downto 0)  := "01011100";  -- K28.2, 0x5C
   constant IDLE_C  : slv(15 downto 0) := (K28_2_C & K28_1_C);

   type StateType is (
      IDLE_S,
      USER_S,
      TS_S,
      MPS_S,
      BSA_SEVR_S,
      BSA_DATA_S,
      CRC_LO_S,
      CRC_HI_S,
      LAST_S);

   type RegType is record
      rxValid   : sl;
      rxData    : slv(15 downto 0);
      rxdataK   : slv(1 downto 0);
      errPktLen : sl;
      errCrc    : sl;
      crcValid  : sl;
      crcRst    : sl;
      crcData   : slv(15 downto 0);
      crc       : slv(31 downto 0);
      userValue : slv(127 downto 0);
      wrd       : natural range 0 to 7;
      cnt       : natural range 0 to 11;
      sofDet    : sl;
      fifoWr    : sl;
      msg       : MsgType;
      state     : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      rxValid   => '0',
      rxData    => (others => '0'),
      rxdataK   => (others => '0'),
      errPktLen => '0',
      errCrc    => '0',
      crcValid  => '0',
      crcRst    => '1',
      crcData   => (others => '0'),
      crc       => (others => '0'),
      userValue => (others => '0'),
      wrd       => 0,
      cnt       => 0,
      sofDet    => '0',
      fifoWr    => '0',
      msg       => MSG_INIT_C,
      state     => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal crcResult : slv(31 downto 0);
   signal overflow  : sl;
   signal fifoDin   : slv(RX_MSG_FIFO_WIDTH_C-1 downto 0);
   signal fifoDout  : slv(RX_MSG_FIFO_WIDTH_C-1 downto 0);

begin

   comb : process (crcResult, r, rxData, rxDecErr, rxDispErr, rxRst, rxValid,
                   rxdataK) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the signals
      v.crcRst    := '0';
      v.crcValid  := '0';
      v.errPktLen := '0';
      v.errCrc    := '0';
      v.sofDet    := '0';
      v.fifoWr    := '0';

      -- Register the 8B10B and check for valid data (help with timing)
      v.rxValid := rxValid and not(uOr(rxDecErr)) and not(uOr(rxDispErr));
      v.rxData  := rxData;
      v.rxdataK := rxdataK;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Reset the counters
            v.wrd := 0;
            v.cnt := 0;
            -- Check for start of packet and Version 1
            if (r.rxValid = '1') and (r.rxdataK = "01") and (r.rxData(7 downto 0) = K28_5_C) and (r.rxData(15 downto 8) = x"01") then
               -- Forward the data to CRC 
               v.crcValid := '1';
               v.crcData  := r.rxData;
               -- Next state
               v.state    := USER_S;
            end if;
         ----------------------------------------------------------------------
         when USER_S =>
            -- Check for valid data
            if (r.rxValid = '1') and (r.rxdataK = "00") then
               -- Forward the data to CRC 
               v.crcValid                                   := '1';
               v.crcData                                    := r.rxData;
               -- Save the bus value
               v.userValue((r.wrd*16)+15 downto (r.wrd*16)) := r.rxData;
               -- Check the counter
               if (r.wrd = 7) then
                  -- Reset the counter
                  v.wrd   := 0;
                  -- Next State
                  v.state := TS_S;
               else
                  -- Increment the counter
                  v.wrd := r.wrd + 1;
               end if;
            else
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when TS_S =>
            -- Check for valid data
            if (r.rxValid = '1') and (r.rxdataK = "00") then
               -- Forward the data to CRC 
               v.crcValid                                       := '1';
               v.crcData                                        := r.rxData;
               -- Save the bus value
               v.msg.timeStamp((r.wrd*16)+15 downto (r.wrd*16)) := r.rxData;
               -- Check the counter
               if (r.wrd = 3) then
                  -- Reset the counter
                  v.wrd   := 0;
                  -- Next State
                  v.state := MPS_S;
               else
                  -- Increment the counter
                  v.wrd := r.wrd + 1;
               end if;
            else
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when MPS_S =>
            -- Check for valid data
            if (r.rxValid = '1') and (r.rxdataK = "00") then
               -- Forward the data to CRC 
               v.crcValid       := '1';
               v.crcData        := r.rxData;
               -- Save the bus value
               v.msg.mpsPermit  := r.rxData(3 downto 0);
               v.msg.bsaSevr(0) := r.rxData(5 downto 4);
               v.msg.bsaSevr(1) := r.rxData(7 downto 6);
               v.msg.bsaSevr(2) := r.rxData(9 downto 8);
               v.msg.bsaSevr(3) := r.rxData(11 downto 10);
               v.msg.bsaSevr(4) := r.rxData(13 downto 12);
               v.msg.bsaSevr(5) := r.rxData(15 downto 14);
               -- Next State
               v.state          := BSA_SEVR_S;
            else
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when BSA_SEVR_S =>
            -- Check for valid data
            if (r.rxValid = '1') and (r.rxdataK = "00") then
               -- Forward the data to CRC 
               v.crcValid        := '1';
               v.crcData         := r.rxData;
               -- Save the bus value
               -- Note: r.rxData(3 downto 0) not used and undefined
               v.msg.bsaSevr(6)  := r.rxData(5 downto 4);
               v.msg.bsaSevr(7)  := r.rxData(7 downto 6);
               v.msg.bsaSevr(8)  := r.rxData(9 downto 8);
               v.msg.bsaSevr(9)  := r.rxData(11 downto 10);
               v.msg.bsaSevr(10) := r.rxData(13 downto 12);
               v.msg.bsaSevr(11) := r.rxData(15 downto 14);
               -- Next State
               v.state           := BSA_DATA_S;
            else
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when BSA_DATA_S =>
            -- Check for valid data
            if (r.rxValid = '1') and (r.rxdataK = "00") then
               -- Forward the data to CRC 
               v.crcValid                                                := '1';
               v.crcData                                                 := r.rxData;
               -- Save the bus value
               v.msg.bsaQuantity(r.cnt)((r.wrd*16)+15 downto (r.wrd*16)) := r.rxData;
               -- Check the counter
               if (r.wrd = 1) then
                  -- Reset the counter
                  v.wrd := 0;
                  -- Check the counter
                  if (r.cnt = 11) then
                     -- Reset the counter
                     v.cnt   := 0;
                     -- Next State
                     v.state := CRC_LO_S;
                  else
                     -- Increment the counter
                     v.cnt := r.cnt + 1;
                  end if;
               else
                  -- Increment the counter
                  v.wrd := r.wrd + 1;
               end if;
            else
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when CRC_LO_S =>
            -- Check for valid data
            if (r.rxValid = '1') and (r.rxdataK = "00") then
               -- Save the bus value         
               v.crc(15 downto 0) := r.rxData;
               -- Next state
               v.state            := CRC_HI_S;
            else
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when CRC_HI_S =>
            -- Check for valid data
            if (r.rxValid = '1') and (r.rxdataK = "00") then
               -- Save the bus value         
               v.crc(31 downto 16) := r.rxData;
               -- Next state
               v.state             := LAST_S;
            else
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when LAST_S =>
            -- Check for valid IDLE and compare CRC values
            if (r.rxValid = '1') and (r.rxdataK = "11") and (r.rxData = IDLE_C) then
               -- Check for valud CRC
               if (r.crc = crcResult) then
                  -- Set the flag
                  v.fifoWr := '1';
               else
                  -- Set the flag
                  v.errCrc := '1';
               end if;
            else
               -- Set the flag
               v.errPktLen := '1';
            end if;
            -- Next state
            v.state := IDLE_S;
      ----------------------------------------------------------------------
      end case;

      -- Check for transitioning back to IDLE state
      if (v.state = IDLE_S) and (r.state /= IDLE_S) then
         -- Reset the CRC module
         v.crcRst   := '1';
         v.crcValid := '0';
         -- Check for packet length error
         if (r.state /= LAST_S) then
            -- Set the flag
            v.errPktLen := '1';
         end if;
      end if;

      -- Monitor for SOF independent of state machine phase
      if (r.rxValid = '1') and (r.rxdataK = "01") and (r.rxData(7 downto 0) = K28_5_C) then
         v.sofDet := '1';
      end if;

      -- Reset
      if (rxRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      fifoDin <= toSlv(r.msg);

   end process comb;

   seq : process (rxClk) is
   begin
      if rising_edge(rxClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -------------
   -- CRC Engine
   -------------
   U_Crc32 : entity surf.Crc32Parallel
      generic map (
         -- TPD_G        => TPD_G,
         BYTE_WIDTH_G => 2)
      port map (
         crcClk       => rxClk,
         crcReset     => r.crcRst,
         crcDataWidth => "001",         -- 2 bytes 
         crcDataValid => r.crcValid,
         crcIn        => r.crcData,
         crcOut       => crcResult);

   ------------
   -- SYNC FIFO
   ------------
   U_Fifo : entity surf.FifoAsync
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "distributed",
         FWFT_EN_G     => true,
         DATA_WIDTH_G  => RX_MSG_FIFO_WIDTH_C,
         ADDR_WIDTH_G  => 5)
      port map (
         rst      => rxRst,
         -- Write Ports
         wr_clk   => rxClk,
         wr_en    => r.fifoWr,
         din      => fifoDin,
         overflow => overflow,
         -- Read Ports
         rd_clk   => axilClk,
         rd_en    => remoteRd,
         dout     => fifoDout,
         valid    => remoteValid);

   remoteMsg <= fromSlv(fifoDout);

   -----------------------
   -- Configuration/Status
   -----------------------
   U_Reg : entity work.BsaMpsMsgRxFramerReg
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- Status/Configuration Interface (rxClk domain)
         rxClk           => rxClk,
         rxRst           => rxRst,
         rxLinkUp        => rxValid,
         rxDecErr        => rxDecErr,
         rxDispErr       => rxDispErr,
         rxBufStatus     => rxBufStatus,
         rxPolarity      => rxPolarity,
         txPolarity      => txPolarity,
         loopback        => loopback,
         cPllLock        => cPllLock,
         fifoWr          => r.fifoWr,
         overflow        => overflow,
         errPktLen       => r.errPktLen,
         errCrc          => r.errCrc,
         sofDet          => r.sofDet,
         userValue       => r.userValue,
         gtRst           => gtRst,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

end rtl;
