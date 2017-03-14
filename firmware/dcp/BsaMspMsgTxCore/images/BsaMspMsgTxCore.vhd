-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
-- Date        : Mon Mar 13 15:57:29 2017
-- Host        : rdsrv222 running 64-bit Red Hat Enterprise Linux Server release 6.8 (Santiago)
-- Command     : write_vhdl -force -mode synth_stub
--               /u/re/ruckman/projects/lcls/lcls2-llrf/firmware/dcp/BsaMspMsgTxCore/images/BsaMspMsgTxCore.vhd
-- Design      : BsaMspMsgTxCore
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k160tffg676-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BsaMspMsgTxCore is
  Port ( 
    usrClk : in STD_LOGIC;
    usrRst : in STD_LOGIC;
    timingStrobe : in STD_LOGIC;
    timeStamp : in STD_LOGIC_VECTOR ( 63 downto 0 );
    bsaQuantity0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity1 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity2 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity3 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity4 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity5 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity6 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity7 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity8 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity9 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity10 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bsaQuantity11 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    mpsPermit : in STD_LOGIC_VECTOR ( 3 downto 0 );
    cPllRefClk : in STD_LOGIC;
    stableClk : in STD_LOGIC;
    stableRst : in STD_LOGIC;
    cPllLock : out STD_LOGIC;
    txPolarity : in STD_LOGIC;
    txPreCursor : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txPostCursor : in STD_LOGIC_VECTOR ( 4 downto 0 );
    txDiffCtrl : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gtTxP : out STD_LOGIC;
    gtTxN : out STD_LOGIC;
    gtRxP : in STD_LOGIC;
    gtRxN : in STD_LOGIC
  );

end BsaMspMsgTxCore;

architecture stub of BsaMspMsgTxCore is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "usrClk,usrRst,timingStrobe,timeStamp[63:0],bsaQuantity0[31:0],bsaQuantity1[31:0],bsaQuantity2[31:0],bsaQuantity3[31:0],bsaQuantity4[31:0],bsaQuantity5[31:0],bsaQuantity6[31:0],bsaQuantity7[31:0],bsaQuantity8[31:0],bsaQuantity9[31:0],bsaQuantity10[31:0],bsaQuantity11[31:0],mpsPermit[3:0],cPllRefClk,stableClk,stableRst,cPllLock,txPolarity,txPreCursor[4:0],txPostCursor[4:0],txDiffCtrl[3:0],gtTxP,gtTxN,gtRxP,gtRxN";
begin
end;
