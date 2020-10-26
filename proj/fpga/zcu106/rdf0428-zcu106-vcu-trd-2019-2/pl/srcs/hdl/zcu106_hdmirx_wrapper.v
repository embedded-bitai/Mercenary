//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (lin64) Build 2552052 Fri May 24 14:47:09 MDT 2019
//Date        : Thu Aug 29 05:28:04 2019
//Host        : xhdcl190030 running 64-bit CentOS Linux release 7.4.1708 (Core)
//Command     : generate_target bd_wrapper.bd
//Design      : bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module zcu106_hdmirx_wrapper
   (DRU_CLK_clk_n,
    DRU_CLK_clk_p,
    HDMI_CTRL_IIC_scl_io,
    HDMI_CTRL_IIC_sda_io,
    HDMI_RX_CLK_N,
    HDMI_RX_CLK_P,
    HDMI_RX_DAT_N,
    HDMI_RX_DAT_P,
    HDMI_TX_CLK_N,
    HDMI_TX_CLK_P,
    HDMI_TX_DAT_N,
    HDMI_TX_DAT_P,
    LED1,
    LED2,
    LED3,
    LED4,
    LED5,
    LED6,
    LED7,
    RX_DDC_scl_io,
    RX_DDC_sda_io,
    RX_DET,
    RX_HPD,
    RX_REFCLK_N,
    RX_REFCLK_P,
    SI5319_LOL,
    SI5319_RST,
    TX_EN,
    TX_REFCLK_N,
    TX_REFCLK_P,
    si570_user_clk_n,
    si570_user_clk_p);
  input [0:0]DRU_CLK_clk_n;
  input [0:0]DRU_CLK_clk_p;
  inout HDMI_CTRL_IIC_scl_io;
  inout HDMI_CTRL_IIC_sda_io;
  input HDMI_RX_CLK_N;
  input HDMI_RX_CLK_P;
  input [2:0]HDMI_RX_DAT_N;
  input [2:0]HDMI_RX_DAT_P;
  output HDMI_TX_CLK_N;
  output HDMI_TX_CLK_P;
  output [2:0]HDMI_TX_DAT_N;
  output [2:0]HDMI_TX_DAT_P;
  output [0:0]LED1;
  output [0:0]LED2;
  output [0:0]LED3;
  output [0:0]LED4;
  output [0:0]LED5;
  output LED6;
  output LED7;
  inout RX_DDC_scl_io;
  inout RX_DDC_sda_io;
  input RX_DET;
  output [0:0]RX_HPD;
  output RX_REFCLK_N;
  output RX_REFCLK_P;
  input SI5319_LOL;
  output [0:0]SI5319_RST;
  output [0:0]TX_EN;
  input TX_REFCLK_N;
  input TX_REFCLK_P;
  input si570_user_clk_n;
  input si570_user_clk_p;

  wire [0:0]DRU_CLK_clk_n;
  wire [0:0]DRU_CLK_clk_p;
  wire HDMI_CTRL_IIC_scl_i;
  wire HDMI_CTRL_IIC_scl_io;
  wire HDMI_CTRL_IIC_scl_o;
  wire HDMI_CTRL_IIC_scl_t;
  wire HDMI_CTRL_IIC_sda_i;
  wire HDMI_CTRL_IIC_sda_io;
  wire HDMI_CTRL_IIC_sda_o;
  wire HDMI_CTRL_IIC_sda_t;
  wire HDMI_RX_CLK_N;
  wire HDMI_RX_CLK_P;
  wire [2:0]HDMI_RX_DAT_N;
  wire [2:0]HDMI_RX_DAT_P;
  wire HDMI_TX_CLK_N;
  wire HDMI_TX_CLK_P;
  wire [2:0]HDMI_TX_DAT_N;
  wire [2:0]HDMI_TX_DAT_P;
  wire [0:0]LED1;
  wire [0:0]LED2;
  wire [0:0]LED3;
  wire [0:0]LED4;
  wire [0:0]LED5;
  wire LED6;
  wire LED7;
  wire RX_DDC_scl_i;
  wire RX_DDC_scl_io;
  wire RX_DDC_scl_o;
  wire RX_DDC_scl_t;
  wire RX_DDC_sda_i;
  wire RX_DDC_sda_io;
  wire RX_DDC_sda_o;
  wire RX_DDC_sda_t;
  wire RX_DET;
  wire [0:0]RX_HPD;
  wire RX_REFCLK_N;
  wire RX_REFCLK_P;
  wire SI5319_LOL;
  wire [0:0]SI5319_RST;
  wire [0:0]TX_EN;
  wire TX_REFCLK_N;
  wire TX_REFCLK_P;
  wire si570_user_clk_n;
  wire si570_user_clk_p;

  IOBUF HDMI_CTRL_IIC_scl_iobuf
       (.I(HDMI_CTRL_IIC_scl_o),
        .IO(HDMI_CTRL_IIC_scl_io),
        .O(HDMI_CTRL_IIC_scl_i),
        .T(HDMI_CTRL_IIC_scl_t));
  IOBUF HDMI_CTRL_IIC_sda_iobuf
       (.I(HDMI_CTRL_IIC_sda_o),
        .IO(HDMI_CTRL_IIC_sda_io),
        .O(HDMI_CTRL_IIC_sda_i),
        .T(HDMI_CTRL_IIC_sda_t));
  IOBUF RX_DDC_scl_iobuf
       (.I(RX_DDC_scl_o),
        .IO(RX_DDC_scl_io),
        .O(RX_DDC_scl_i),
        .T(RX_DDC_scl_t));
  IOBUF RX_DDC_sda_iobuf
       (.I(RX_DDC_sda_o),
        .IO(RX_DDC_sda_io),
        .O(RX_DDC_sda_i),
        .T(RX_DDC_sda_t));
  bd bd_i
       (.DRU_CLK_clk_n(DRU_CLK_clk_n),
        .DRU_CLK_clk_p(DRU_CLK_clk_p),
        .HDMI_CTRL_IIC_scl_i(HDMI_CTRL_IIC_scl_i),
        .HDMI_CTRL_IIC_scl_o(HDMI_CTRL_IIC_scl_o),
        .HDMI_CTRL_IIC_scl_t(HDMI_CTRL_IIC_scl_t),
        .HDMI_CTRL_IIC_sda_i(HDMI_CTRL_IIC_sda_i),
        .HDMI_CTRL_IIC_sda_o(HDMI_CTRL_IIC_sda_o),
        .HDMI_CTRL_IIC_sda_t(HDMI_CTRL_IIC_sda_t),
        .HDMI_RX_CLK_N(HDMI_RX_CLK_N),
        .HDMI_RX_CLK_P(HDMI_RX_CLK_P),
        .HDMI_RX_DAT_N(HDMI_RX_DAT_N),
        .HDMI_RX_DAT_P(HDMI_RX_DAT_P),
        .HDMI_TX_CLK_N(HDMI_TX_CLK_N),
        .HDMI_TX_CLK_P(HDMI_TX_CLK_P),
        .HDMI_TX_DAT_N(HDMI_TX_DAT_N),
        .HDMI_TX_DAT_P(HDMI_TX_DAT_P),
        .LED1(LED1),
        .LED2(LED2),
        .LED3(LED3),
        .LED4(LED4),
        .LED5(LED5),
        .LED6(LED6),
        .LED7(LED7),
        .RX_DDC_scl_i(RX_DDC_scl_i),
        .RX_DDC_scl_o(RX_DDC_scl_o),
        .RX_DDC_scl_t(RX_DDC_scl_t),
        .RX_DDC_sda_i(RX_DDC_sda_i),
        .RX_DDC_sda_o(RX_DDC_sda_o),
        .RX_DDC_sda_t(RX_DDC_sda_t),
        .RX_DET(RX_DET),
        .RX_HPD(RX_HPD),
        .RX_REFCLK_N(RX_REFCLK_N),
        .RX_REFCLK_P(RX_REFCLK_P),
        .SI5319_LOL(SI5319_LOL),
        .SI5319_RST(SI5319_RST),
        .TX_EN(TX_EN),
        .TX_REFCLK_N(TX_REFCLK_N),
        .TX_REFCLK_P(TX_REFCLK_P),
        .si570_user_clk_n(si570_user_clk_n),
        .si570_user_clk_p(si570_user_clk_p));
endmodule
