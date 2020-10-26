//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (lin64) Build 2552052 Fri May 24 14:47:09 MDT 2019
//Date        : Fri Aug 30 04:47:25 2019
//Host        : xhdlc190423 running 64-bit CentOS Linux release 7.4.1708 (Core)
//Command     : generate_target bd_wrapper.bd
//Design      : bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module zcu106_audio_wrapper
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
    LED0,
    LED2,
    LED3,
    LED4,
    LED5,
    LED6,
    LED7,
    OBUF_DS_N_0,
    OBUF_DS_P_0,
    RESET,
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
    bg1_pin0_nc_0,
    bg3_pin0_nc_0,
    lrclk_rx,
    lrclk_tx,
    mclk_out_rx,
    mclk_out_tx,
    mipi_phy_if_0_0_clk_n,
    mipi_phy_if_0_0_clk_p,
    mipi_phy_if_0_0_data_n,
    mipi_phy_if_0_0_data_p,
    sclk_rx,
    sclk_tx,
    sdata_rx,
    sdata_tx,
    sensor_gpio_flash,
    sensor_gpio_rst,
    sensor_gpio_spi_cs_n,
    sensor_iic_scl_io,
    sensor_iic_sda_io,
    si570_mclk_out,
    user_si570_sysclk_clk_n,
    user_si570_sysclk_clk_p);
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
  output [0:0]LED2;
  output [0:0]LED3;
  output [0:0]LED4;
  output [0:0]LED5;
  output LED6;
  output LED7;
  output [0:0]OBUF_DS_N_0;
  output [0:0]OBUF_DS_P_0;
  input RESET;
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
  input bg1_pin0_nc_0;
  input bg3_pin0_nc_0;
  output lrclk_rx;
  output lrclk_tx;
  output mclk_out_rx;
  output mclk_out_tx;
  input mipi_phy_if_0_0_clk_n;
  input mipi_phy_if_0_0_clk_p;
  input [3:0]mipi_phy_if_0_0_data_n;
  input [3:0]mipi_phy_if_0_0_data_p;
  output sclk_rx;
  output sclk_tx;
  input sdata_rx;
  output sdata_tx;
  output [0:0]sensor_gpio_flash;
  output [0:0]sensor_gpio_rst;
  output [0:0]sensor_gpio_spi_cs_n;
  inout sensor_iic_scl_io;
  inout sensor_iic_sda_io;
  output si570_mclk_out;
  input [0:0]user_si570_sysclk_clk_n;
  input [0:0]user_si570_sysclk_clk_p;

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
  wire [0:0]LED2;
  wire [0:0]LED3;
  wire [0:0]LED4;
  wire [0:0]LED5;
  wire LED6;
  wire LED7;
  wire [0:0]OBUF_DS_N_0;
  wire [0:0]OBUF_DS_P_0;
  wire RESET;
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
  wire bg1_pin0_nc_0;
  wire bg3_pin0_nc_0;
  wire lrclk_rx;
  wire lrclk_tx;
  wire mclk_out_rx;
  wire mclk_out_tx;
  wire mipi_phy_if_0_0_clk_n;
  wire mipi_phy_if_0_0_clk_p;
  wire [3:0]mipi_phy_if_0_0_data_n;
  wire [3:0]mipi_phy_if_0_0_data_p;
  wire sclk_rx;
  wire sclk_tx;
  wire sdata_rx;
  wire sdata_tx;
  wire [0:0]sensor_gpio_flash;
  wire [0:0]sensor_gpio_rst;
  wire [0:0]sensor_gpio_spi_cs_n;
  wire sensor_iic_scl_i;
  wire sensor_iic_scl_io;
  wire sensor_iic_scl_o;
  wire sensor_iic_scl_t;
  wire sensor_iic_sda_i;
  wire sensor_iic_sda_io;
  wire sensor_iic_sda_o;
  wire sensor_iic_sda_t;
  wire si570_mclk_out;
  wire [0:0]user_si570_sysclk_clk_n;
  wire [0:0]user_si570_sysclk_clk_p;

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
        .LED0(LED0),
        .LED2(LED2),
        .LED3(LED3),
        .LED4(LED4),
        .LED5(LED5),
        .LED6(LED6),
        .LED7(LED7),
        .OBUF_DS_N_0(OBUF_DS_N_0),
        .OBUF_DS_P_0(OBUF_DS_P_0),
        .RESET(RESET),
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
        .bg1_pin0_nc_0(bg1_pin0_nc_0),
        .bg3_pin0_nc_0(bg3_pin0_nc_0),
        .lrclk_rx(lrclk_rx),
        .lrclk_tx(lrclk_tx),
        .mclk_out_rx(mclk_out_rx),
        .mclk_out_tx(mclk_out_tx),
        .mipi_phy_if_0_0_clk_n(mipi_phy_if_0_0_clk_n),
        .mipi_phy_if_0_0_clk_p(mipi_phy_if_0_0_clk_p),
        .mipi_phy_if_0_0_data_n(mipi_phy_if_0_0_data_n),
        .mipi_phy_if_0_0_data_p(mipi_phy_if_0_0_data_p),
        .sclk_rx(sclk_rx),
        .sclk_tx(sclk_tx),
        .sdata_rx(sdata_rx),
        .sdata_tx(sdata_tx),
        .sensor_gpio_flash(sensor_gpio_flash),
        .sensor_gpio_rst(sensor_gpio_rst),
        .sensor_gpio_spi_cs_n(sensor_gpio_spi_cs_n),
        .sensor_iic_scl_i(sensor_iic_scl_i),
        .sensor_iic_scl_o(sensor_iic_scl_o),
        .sensor_iic_scl_t(sensor_iic_scl_t),
        .sensor_iic_sda_i(sensor_iic_sda_i),
        .sensor_iic_sda_o(sensor_iic_sda_o),
        .sensor_iic_sda_t(sensor_iic_sda_t),
        .si570_mclk_out(si570_mclk_out),
        .user_si570_sysclk_clk_n(user_si570_sysclk_clk_n),
        .user_si570_sysclk_clk_p(user_si570_sysclk_clk_p));
  IOBUF sensor_iic_scl_iobuf
       (.I(sensor_iic_scl_o),
        .IO(sensor_iic_scl_io),
        .O(sensor_iic_scl_i),
        .T(sensor_iic_scl_t));
  IOBUF sensor_iic_sda_iobuf
       (.I(sensor_iic_sda_o),
        .IO(sensor_iic_sda_io),
        .O(sensor_iic_sda_i),
        .T(sensor_iic_sda_t));
endmodule
