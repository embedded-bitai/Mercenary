//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (lin64) Build 2552052 Fri May 24 14:47:09 MDT 2019
//Date        : Thu Aug 29 05:55:04 2019
//Host        : xhdcl190030 running 64-bit CentOS Linux release 7.4.1708 (Core)
//Command     : generate_target bd_wrapper.bd
//Design      : bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module zcu106_pcie_wrapper
   (lnk_up_led,
    pcie4_mgt_0_0_rxn,
    pcie4_mgt_0_0_rxp,
    pcie4_mgt_0_0_txn,
    pcie4_mgt_0_0_txp,
    perst_n,
    ref_clk_0_clk_n,
    ref_clk_0_clk_p,
    si570_user_clk_n,
    si570_user_clk_p);
  output lnk_up_led;
  input [3:0]pcie4_mgt_0_0_rxn;
  input [3:0]pcie4_mgt_0_0_rxp;
  output [3:0]pcie4_mgt_0_0_txn;
  output [3:0]pcie4_mgt_0_0_txp;
  input perst_n;
  input [0:0]ref_clk_0_clk_n;
  input [0:0]ref_clk_0_clk_p;
  input si570_user_clk_n;
  input si570_user_clk_p;

  wire lnk_up_led;
  wire [3:0]pcie4_mgt_0_0_rxn;
  wire [3:0]pcie4_mgt_0_0_rxp;
  wire [3:0]pcie4_mgt_0_0_txn;
  wire [3:0]pcie4_mgt_0_0_txp;
  wire perst_n;
  wire [0:0]ref_clk_0_clk_n;
  wire [0:0]ref_clk_0_clk_p;
  wire si570_user_clk_n;
  wire si570_user_clk_p;

  bd bd_i
       (.lnk_up_led(lnk_up_led),
        .pcie4_mgt_0_0_rxn(pcie4_mgt_0_0_rxn),
        .pcie4_mgt_0_0_rxp(pcie4_mgt_0_0_rxp),
        .pcie4_mgt_0_0_txn(pcie4_mgt_0_0_txn),
        .pcie4_mgt_0_0_txp(pcie4_mgt_0_0_txp),
        .perst_n(perst_n),
        .ref_clk_0_clk_n(ref_clk_0_clk_n),
        .ref_clk_0_clk_p(ref_clk_0_clk_p),
        .si570_user_clk_n(si570_user_clk_n),
        .si570_user_clk_p(si570_user_clk_p));
endmodule
