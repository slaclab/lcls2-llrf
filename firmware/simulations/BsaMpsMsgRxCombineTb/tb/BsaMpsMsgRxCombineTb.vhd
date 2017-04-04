-------------------------------------------------------------------------------
-- File       : BsaMpsMsgRxCombineTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-13
-- Last update: 2017-04-04
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
use work.AxiLitePkg.all;
use work.BsaMpsMsgRxFramerPkg.all;

entity BsaMpsMsgRxCombineTb is end BsaMpsMsgRxCombineTb;

architecture testbed of BsaMpsMsgRxCombineTb is

   constant CLK_PERIOD_C : time    := 5.384 ns;
   constant TPD_G        : time    := CLK_PERIOD_C/4;
   constant TIMEOUT_C    : natural := 185;  -- ~ 1MHz strobe    

   type RegType is record
      timingBus : TimingBusType;
      timer     : natural range 0 to TIMEOUT_C;
   end record RegType;
   constant REG_INIT_C : RegType := (
      timingBus  => TIMING_BUS_INIT_C,
      timer  => 0);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal clk : sl := '0';
   signal rst : sl := '0';

   signal linkP : slv(1 downto 0)       := (others => '0');
   signal linkN : slv(1 downto 0)       := (others => '1');

   signal txData    : slv(15 downto 0) := (others => '0');
   signal txDataK   : slv(1 downto 0)  := (others => '0');

   signal fifoRd    : slv(1 downto 0)       := (others => '0');
   signal fifoValid : slv(1 downto 0)       := (others => '0');
   signal remoteMsg : MsgArray(1 downto 0) :=(others =>MSG_INIT_C);

   signal diagnosticBus : DiagnosticBusType := DIAGNOSTIC_BUS_INIT_C;

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
      v.timingBus.strobe := '0';
      
      -- Set valid timing link
      v.timingBus.valid     := '1';
      v.timingBus.v2.linkUp := '1';
      
      -- Check the timer
      if (r.timer = TIMEOUT_C) then
         -- Reset the counter
         v.timer  := 0;
         -- Increment the counter
         v.timingBus.message.timeStamp    := r.timingBus.message.timeStamp + 1;
         -- Set the flag
         v.timingBus.strobe := '1';
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

   ---------------------
   -- TX Frame Generator
   ---------------------
   U_Tx : entity work.BsaMpsMsgTxFramer
      generic map (
         TPD_G                 => TPD_G)
      port map (
         -- BSA/MPS Interface (usrClk domain)
         usrClk        => clk,
         usrRst        => rst,
         timingStrobe  => r.timingBus.strobe,
         timeStamp     => r.timingBus.message.timeStamp,
         bsaQuantity0  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity1  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity2  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity3  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity4  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity5  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity6  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity7  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity8  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity9  => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity10 => r.timingBus.message.timeStamp(31 downto 0),
         bsaQuantity11 => r.timingBus.message.timeStamp(31 downto 0),
         mpsPermit     => r.timingBus.message.timeStamp(3 downto 0),
         -- TX Data Interface (txClk domain)
         txClk         => clk,
         txRst         => rst,
         txData        => txData,
         txDataK       => txDataK);

   --------------------
   -- BSA/MPS Receivers
   --------------------
   GEN_VEC : for i in 1 downto 0 generate
      U_BsaMpsMsgRx : entity work.BsaMpsMsgRxCore
         generic map (
            TPD_G            => TPD_G,
            SIMULATION_G     => true)
         port map (
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => clk,
            axilRst         => rst,
            axilReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
            axilReadSlave   => open,
            axilWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
            axilWriteSlave  => open,
            -- RX Frame Interface (axilClk domain)     
            fifoRd          => fifoRd(i),
            fifoValid       => fifoValid(i),
            remoteMsg       => remoteMsg(i),
            -- TX Data Interface (txClk domain)
            txClk           => clk,
            txRst           => rst,
            txData          => txData,
            txDataK         => txDataK,
            -- Remote LLRF BSA/MPS Ports
            refClk          => clk,
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
         TPD_G            => TPD_G,
         SIMULATION_G     => true)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => clk,
         axilRst         => rst,
         axilReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
         axilReadSlave   => open,
         axilWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
         axilWriteSlave  => open,
         -- RX Frame Interface
         fifoRd          => fifoRd,
         fifoValid       => fifoValid,
         remoteMsg       => remoteMsg,
         -- Timing Interface
         timingBus       => r.timingBus,
         -- Diagnostic Interface
         diagnosticBus   => diagnosticBus);

end testbed;
