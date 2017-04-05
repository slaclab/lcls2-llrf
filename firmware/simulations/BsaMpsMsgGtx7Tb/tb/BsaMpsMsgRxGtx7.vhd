-------------------------------------------------------------------------------
-- File       : BsaMpsMsgRxGtx7.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-13
-- Last update: 2017-04-04
-------------------------------------------------------------------------------
-- Description: GTX7 Wrapper
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

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity BsaMpsMsgRxGtx7 is
   generic (
      TPD_G                 : time       := 1 ns;
      CPLL_REFCLK_SEL_G     : bit_vector := "001";
      SIM_GTRESET_SPEEDUP_G : string     := "FALSE";
      SIMULATION_G          : boolean    := false);
   port (
      -- Clock and Reset
      cPllRefClk : in  sl;
      stableClk  : in  sl;
      stableRst  : in  sl;
      -- GTX Interface
      gtTxP      : out sl;
      gtTxN      : out sl;
      gtRxP      : in  sl;
      gtRxN      : in  sl;
      -- RX Interface
      rxClk      : in  sl;
      rxRst      : in  sl;
      rxValid    : out sl;
      rxData     : out slv(15 downto 0);
      rxdataK    : out slv(1 downto 0);
      rxDecErr   : out slv(1 downto 0);
      rxDispErr  : out slv(1 downto 0));
end BsaMpsMsgRxGtx7;

architecture mapping of BsaMpsMsgRxGtx7 is

   constant DURATION_100MS_C : positive := ite(SIMULATION_G, 255, 25000000);
   constant DURATION_1S_C    : positive := (10*DURATION_100MS_C);

   signal cnt           : slv(31 downto 0) := (others => '0');
   signal data          : slv(15 downto 0) := (others => '0');
   signal dataK         : slv(1 downto 0)  := (others => '0');
   signal decErr        : slv(1 downto 0)  := (others => '0');
   signal dispErr       : slv(1 downto 0)  := (others => '0');
   signal rxBuff        : slv(2 downto 0)  := (others => '0');
   signal rxRstDone     : sl               := '0';
   signal linkUp        : sl               := '0';
   signal dataValid     : sl               := '0';
   signal rxReset       : sl               := '0';
   signal wdtRstOneShot : sl               := '0';
   signal wdtReset      : sl               := '0';
   signal wdtRst        : sl               := '0';

begin

   rxValid   <= linkUp;
   rxData    <= data  when(linkUp = '1') else (others => '0');
   rxDataK   <= dataK when(linkUp = '1') else (others => '0');
   dataValid <= not (uOr(decErr) or uOr(dispErr));

   process(rxClk)
   begin
      if rising_edge(rxClk) then
         rxReset <= rxRst or wdtRst after TPD_G;
         if (rxRst = '1') or (rxRstDone = '0') or (dataValid = '0') or (rxBuff(2) = '1') then
            cnt    <= (others => '0') after TPD_G;
            linkUp <= '0'             after TPD_G;
         else
            if (cnt = DURATION_100MS_C) then
               linkUp <= '1' after TPD_G;
            else
               cnt <= cnt + 1 after TPD_G;
            end if;
         end if;
      end if;
   end process;

   -------------------------
   -- Watchdog State Machine
   -------------------------
   wdtReset <= (not(dataValid) and linkUp) or wdtRstOneShot;
   U_PwrUpRst : entity work.PwrUpRst
      generic map(
         TPD_G      => TPD_G,
         DURATION_G => DURATION_100MS_C)
      port map (
         arst   => wdtReset,
         clk    => rxClk,
         rstOut => wdtRst);

   U_WatchDogRst : entity work.WatchDogRst
      generic map(
         TPD_G      => TPD_G,
         DURATION_G => DURATION_1S_C)
      port map (
         clk    => rxClk,
         monIn  => linkUp,
         rstOut => wdtRstOneShot);

   -------------------------
   -- Watchdog State Machine
   -------------------------   
   Gtx7Core_Inst : entity work.Gtx7Core
      generic map (
         -- SIM Generics
         TPD_G                    => TPD_G,
         SIM_GTRESET_SPEEDUP_G    => SIM_GTRESET_SPEEDUP_G,
         SIMULATION_G             => SIMULATION_G,
         -- CPLL Settings
         CPLL_REFCLK_SEL_G        => CPLL_REFCLK_SEL_G,
         CPLL_FBDIV_G             => 2,
         CPLL_FBDIV_45_G          => 5,
         CPLL_REFCLK_DIV_G        => 1,
         RXOUT_DIV_G              => 1,
         TXOUT_DIV_G              => 1,
         RX_CLK25_DIV_G           => 10,
         TX_CLK25_DIV_G           => 10,
         PMA_RSV_G                => x"00018480",
         RX_OS_CFG_G              => "0000010000000",
         RXCDR_CFG_G              => x"03000023ff20400020",
         -- Configure PLL sources         
         TX_PLL_G                 => "CPLL",
         RX_PLL_G                 => "CPLL",
         -- Configure Data widths
         TX_EXT_DATA_WIDTH_G      => 16,
         TX_INT_DATA_WIDTH_G      => 20,
         TX_8B10B_EN_G            => true,
         RX_EXT_DATA_WIDTH_G      => 16,
         RX_INT_DATA_WIDTH_G      => 20,
         RX_8B10B_EN_G            => true,
         TX_BUF_EN_G              => true,
         -- Configure Buffer usage
         TX_OUTCLK_SRC_G          => "OUTCLKPMA",
         TX_DLY_BYPASS_G          => '1',
         TX_PHASE_ALIGN_G         => "NONE",
         TX_BUF_ADDR_MODE_G       => "FULL",
         RX_BUF_EN_G              => true,
         RX_OUTCLK_SRC_G          => "OUTCLKPMA",
         RX_USRCLK_SRC_G          => "RXOUTCLK",
         RX_DLY_BYPASS_G          => '1',
         RX_DDIEN_G               => '0',
         RX_BUF_ADDR_MODE_G       => "FULL",
         -- Configure RX comma alignment
         RX_ALIGN_MODE_G          => "GT",
         ALIGN_COMMA_DOUBLE_G     => "FALSE",
         ALIGN_COMMA_ENABLE_G     => "1111111111",
         ALIGN_COMMA_WORD_G       => 2,
         ALIGN_MCOMMA_DET_G       => "TRUE",
         ALIGN_MCOMMA_VALUE_G     => "0110000011",  -- K28.1
         ALIGN_MCOMMA_EN_G        => '1',
         ALIGN_PCOMMA_DET_G       => "TRUE",
         ALIGN_PCOMMA_VALUE_G     => "1001111100",  -- K28.1
         ALIGN_PCOMMA_EN_G        => '1',
         SHOW_REALIGN_COMMA_G     => "FALSE",
         RXSLIDE_MODE_G           => "AUTO",
         -- Configure Clock Correction
         CLK_CORRECT_USE_G        => "TRUE",
         CBCC_DATA_SOURCE_SEL_G   => "DECODED",
         CLK_COR_SEQ_2_USE_G      => "FALSE",
         CLK_COR_KEEP_IDLE_G      => "TRUE",  -- Need atleast one IDLE to align to the end of WIB frame
         CLK_COR_MAX_LAT_G        => 35,
         CLK_COR_MIN_LAT_G        => 32,
         CLK_COR_PRECEDENCE_G     => "TRUE",
         CLK_COR_REPEAT_WAIT_G    => 8,  -- Must be greater than the 6 IDLE bytes per frame
         CLK_COR_SEQ_LEN_G        => 2,
         CLK_COR_SEQ_1_ENABLE_G   => "0011",
         CLK_COR_SEQ_1_1_G        => "0100111100",  -- K28.1 
         CLK_COR_SEQ_1_2_G        => "0101011100",  -- K28.2
         CLK_COR_SEQ_1_3_G        => "0000000000",
         CLK_COR_SEQ_1_4_G        => "0000000000",
         CLK_COR_SEQ_2_ENABLE_G   => "0000",
         CLK_COR_SEQ_2_1_G        => "0000000000",
         CLK_COR_SEQ_2_2_G        => "0000000000",
         CLK_COR_SEQ_2_3_G        => "0000000000",
         CLK_COR_SEQ_2_4_G        => "0000000000",
         -- Configure Clock Correction
         RX_CHAN_BOND_EN_G        => true,  -- For some unknown reason, channel bonding required to make the clock correction to work
         RX_CHAN_BOND_MASTER_G    => true,
         CHAN_BOND_KEEP_ALIGN_G   => "FALSE",
         CHAN_BOND_MAX_SKEW_G     => 10,
         CHAN_BOND_SEQ_LEN_G      => 1,
         CHAN_BOND_SEQ_1_ENABLE_G => "0011",
         CHAN_BOND_SEQ_1_1_G      => "0100111100",  -- K28.1 
         CHAN_BOND_SEQ_1_2_G      => "0101011100",  -- K28.2
         CHAN_BOND_SEQ_1_3_G      => "0000000000",
         CHAN_BOND_SEQ_1_4_G      => "0000000000",
         CHAN_BOND_SEQ_2_ENABLE_G => "0000",
         CHAN_BOND_SEQ_2_1_G      => "0000000000",
         CHAN_BOND_SEQ_2_2_G      => "0000000000",
         CHAN_BOND_SEQ_2_3_G      => "0000000000",
         CHAN_BOND_SEQ_2_4_G      => "0000000000",
         CHAN_BOND_SEQ_2_USE_G    => "FALSE",
         -- RX Equalizer Attributes
         RX_EQUALIZER_G           => "DFE",
         RX_DFE_KL_CFG2_G         => X"301148AC",
         RX_CM_TRIM_G             => "010",
         RX_DFE_LPM_CFG_G         => x"0954",
         RXDFELFOVRDEN_G          => '1',
         RXDFEXYDEN_G             => '1')
      port map (
         stableClkIn      => stableClk,
         cPllRefClkIn     => cPllRefClk,
         cPllLockOut      => open,
         qPllRefClkIn     => '0',
         qPllClkIn        => '0',
         qPllLockIn       => '1',
         qPllRefClkLostIn => open,
         qPllResetOut     => open,
         gtTxP            => gtTxP,
         gtTxN            => gtTxN,
         gtRxP            => gtRxP,
         gtRxN            => gtRxN,
         rxOutClkOut      => open,
         rxUsrClkIn       => rxClk,
         rxUsrClk2In      => rxClk,
         rxUserRdyOut     => open,
         rxMmcmResetOut   => open,
         rxMmcmLockedIn   => '1',
         rxUserResetIn    => rxReset,
         rxResetDoneOut   => rxRstDone,
         rxDataValidIn    => '1',
         rxSlideIn        => '0',
         rxDataOut        => data,
         rxCharIsKOut     => dataK,
         rxDecErrOut      => decErr,
         rxDispErrOut     => dispErr,
         rxPolarityIn     => '0',
         rxBufStatusOut   => rxBuff,
         rxChBondLevelIn  => "000",
         rxChBondIn       => "00000",
         rxChBondOut      => open,
         txOutClkOut      => open,
         txUsrClkIn       => rxClk,
         txUsrClk2In      => rxClk,
         txUserRdyOut     => open,
         txMmcmResetOut   => open,
         txMmcmLockedIn   => '1',
         txUserResetIn    => stableRst,
         txResetDoneOut   => open,
         txDataIn         => x"0000",
         txCharIsKIn      => "00",
         txPolarityIn     => '0',
         txBufStatusOut   => open,
         txPowerDown      => "11",
         rxPowerDown      => "00",
         loopbackIn       => "000",
         txPreCursor      => "00000",
         txPostCursor     => "00000",
         txDiffCtrl       => "1111");

end mapping;
