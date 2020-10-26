//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (lin64) Build 2552052 Fri May 24 14:47:09 MDT 2019
//Date        : Fri Aug 30 04:57:36 2019
//Host        : xhdlc190423 running 64-bit CentOS Linux release 7.4.1708 (Core)
//Command     : generate_target bd_wrapper.bd
//Design      : bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module zcu106_plddr_hdmi_wrapper
   (C0_DDR4_act_n,
    C0_DDR4_adr,
    C0_DDR4_ba,
    C0_DDR4_bg,
    C0_DDR4_ck_c,
    C0_DDR4_ck_t,
    C0_DDR4_cke,
    C0_DDR4_cs_n,
    C0_DDR4_dm_n,
    C0_DDR4_dq,
    C0_DDR4_dqs_c,
    C0_DDR4_dqs_t,
    C0_DDR4_odt,
    C0_DDR4_reset_n,
    DRU_CLK_clk_n,
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
    LED0,
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
    TX_DDC_scl_io,
    TX_DDC_sda_io,
    TX_EN,
    TX_HPD,
    TX_REFCLK_N,
    TX_REFCLK_P,
    mig_sys_clk_n,
    mig_sys_clk_p,
    si570_user_clk_n,
    si570_user_clk_p);
  output [0:0]C0_DDR4_act_n;
  output [16:0]C0_DDR4_adr;
  output [1:0]C0_DDR4_ba;
  output [0:0]C0_DDR4_bg;
  output [0:0]C0_DDR4_ck_c;
  output [0:0]C0_DDR4_ck_t;
  output [0:0]C0_DDR4_cke;
  output [0:0]C0_DDR4_cs_n;
  inout [7:0]C0_DDR4_dm_n;
  inout [63:0]C0_DDR4_dq;
  inout [7:0]C0_DDR4_dqs_c;
  inout [7:0]C0_DDR4_dqs_t;
  output [0:0]C0_DDR4_odt;
  output [0:0]C0_DDR4_reset_n;
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
  output LED0;
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
  inout TX_DDC_scl_io;
  inout TX_DDC_sda_io;
  output [0:0]TX_EN;
  input TX_HPD;
  input TX_REFCLK_N;
  input TX_REFCLK_P;
  input [0:0]mig_sys_clk_n;
  input [0:0]mig_sys_clk_p;
  input si570_user_clk_n;
  input si570_user_clk_p;

  wire [0:0]C0_DDR4_act_n;
  wire [16:0]C0_DDR4_adr;
  wire [1:0]C0_DDR4_ba;
  wire [0:0]C0_DDR4_bg;
  wire [0:0]C0_DDR4_ck_c;
  wire [0:0]C0_DDR4_ck_t;
  wire [0:0]C0_DDR4_cke;
  wire [0:0]C0_DDR4_cs_n;
  wire [7:0]C0_DDR4_dm_n;
  wire [63:0]C0_DDR4_dq;
  wire [7:0]C0_DDR4_dqs_c;
  wire [7:0]C0_DDR4_dqs_t;
  wire [0:0]C0_DDR4_odt;
  wire [0:0]C0_DDR4_reset_n;
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
  wire LED0;
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
  wire TX_DDC_scl_i;
  wire TX_DDC_scl_io;
  wire TX_DDC_scl_o;
  wire TX_DDC_scl_t;
  wire TX_DDC_sda_i;
  wire TX_DDC_sda_io;
  wire TX_DDC_sda_o;
  wire TX_DDC_sda_t;
  wire [0:0]TX_EN;
  wire TX_HPD;
  wire TX_REFCLK_N;
  wire TX_REFCLK_P;
  wire [0:0]mig_sys_clk_n;
  wire [0:0]mig_sys_clk_p;
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
  IOBUF TX_DDC_scl_iobuf
       (.I(TX_DDC_scl_o),
        .IO(TX_DDC_scl_io),
        .O(TX_DDC_scl_i),
        .T(TX_DDC_scl_t));
  IOBUF TX_DDC_sda_iobuf
       (.I(TX_DDC_sda_o),
        .IO(TX_DDC_sda_io),
        .O(TX_DDC_sda_i),
        .T(TX_DDC_sda_t));
  bd bd_i
       (.C0_DDR4_act_n(C0_DDR4_act_n),
        .C0_DDR4_adr(C0_DDR4_adr),
        .C0_DDR4_ba(C0_DDR4_ba),
        .C0_DDR4_bg(C0_DDR4_bg),
        .C0_DDR4_ck_c(C0_DDR4_ck_c),
        .C0_DDR4_ck_t(C0_DDR4_ck_t),
        .C0_DDR4_cke(C0_DDR4_cke),
        .C0_DDR4_cs_n(C0_DDR4_cs_n),
        .C0_DDR4_dm_n(C0_DDR4_dm_n),
        .C0_DDR4_dq(C0_DDR4_dq),
        .C0_DDR4_dqs_c(C0_DDR4_dqs_c),
        .C0_DDR4_dqs_t(C0_DDR4_dqs_t),
        .C0_DDR4_odt(C0_DDR4_odt),
        .C0_DDR4_reset_n(C0_DDR4_reset_n),
        .DRU_CLK_clk_n(DRU_CLK_clk_n),
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
        .LED0(LED0),
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
        .TX_DDC_scl_i(TX_DDC_scl_i),
        .TX_DDC_scl_o(TX_DDC_scl_o),
        .TX_DDC_scl_t(TX_DDC_scl_t),
        .TX_DDC_sda_i(TX_DDC_sda_i),
        .TX_DDC_sda_o(TX_DDC_sda_o),
        .TX_DDC_sda_t(TX_DDC_sda_t),
        .TX_EN(TX_EN),
        .TX_HPD(TX_HPD),
        .TX_REFCLK_N(TX_REFCLK_N),
        .TX_REFCLK_P(TX_REFCLK_P),
        .mig_sys_clk_n(mig_sys_clk_n),
        .mig_sys_clk_p(mig_sys_clk_p),
        .si570_user_clk_n(si570_user_clk_n),
        .si570_user_clk_p(si570_user_clk_p));
endmodule
