// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
// Date        : Thu Mar 16 11:11:21 2017
// Host        : rdsrv223 running 64-bit Red Hat Enterprise Linux Server release 6.8 (Santiago)
// Command     : write_verilog -force -mode synth_stub
//               /u/re/ruckman/projects/lcls/lcls2-llrf/firmware/dcp/BsaMspMsgTxCore/images/BsaMspMsgTxCore.v
// Design      : BsaMspMsgTxCore
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k160tffg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module BsaMspMsgTxCore(usrClk, usrRst, timingStrobe, timeStamp, 
  bsaQuantity0, bsaQuantity1, bsaQuantity2, bsaQuantity3, bsaQuantity4, bsaQuantity5, 
  bsaQuantity6, bsaQuantity7, bsaQuantity8, bsaQuantity9, bsaQuantity10, bsaQuantity11, 
  mpsPermit, cPllRefClk, stableClk, stableRst, cPllLock, txPreCursor, txPostCursor, txDiffCtrl, 
  gtTxP, gtTxN, gtRxP, gtRxN)
/* synthesis syn_black_box black_box_pad_pin="usrClk,usrRst,timingStrobe,timeStamp[63:0],bsaQuantity0[31:0],bsaQuantity1[31:0],bsaQuantity2[31:0],bsaQuantity3[31:0],bsaQuantity4[31:0],bsaQuantity5[31:0],bsaQuantity6[31:0],bsaQuantity7[31:0],bsaQuantity8[31:0],bsaQuantity9[31:0],bsaQuantity10[31:0],bsaQuantity11[31:0],mpsPermit[3:0],cPllRefClk,stableClk,stableRst,cPllLock,txPreCursor[4:0],txPostCursor[4:0],txDiffCtrl[3:0],gtTxP,gtTxN,gtRxP,gtRxN" */;
  input usrClk;
  input usrRst;
  input timingStrobe;
  input [63:0]timeStamp;
  input [31:0]bsaQuantity0;
  input [31:0]bsaQuantity1;
  input [31:0]bsaQuantity2;
  input [31:0]bsaQuantity3;
  input [31:0]bsaQuantity4;
  input [31:0]bsaQuantity5;
  input [31:0]bsaQuantity6;
  input [31:0]bsaQuantity7;
  input [31:0]bsaQuantity8;
  input [31:0]bsaQuantity9;
  input [31:0]bsaQuantity10;
  input [31:0]bsaQuantity11;
  input [3:0]mpsPermit;
  input cPllRefClk;
  input stableClk;
  input stableRst;
  output cPllLock;
  input [4:0]txPreCursor;
  input [4:0]txPostCursor;
  input [3:0]txDiffCtrl;
  output gtTxP;
  output gtTxN;
  input gtRxP;
  input gtRxN;
endmodule
