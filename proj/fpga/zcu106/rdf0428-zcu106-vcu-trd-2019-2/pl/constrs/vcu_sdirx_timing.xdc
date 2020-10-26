#------------------------------------------------------------------------------
#    ____  ____
#  /   /\/   /
# /___/  \  /    Vendor: Xilinx
# \   \   \/     Version: $Revision: #1 $
# #  /   /         Filename: $File: zcu102_uhdsdi_demo_timing.xdc $
# /___/   /\     Timestamp: $DateTime: 2015/04/16 10:29:23 $
# \   \  /
#  \___\/\___
#
# Description:
#   This is the Vivado timing constraints file for the zcu102 UHD-SDI demo.
#------------------------------------------------------------------------------
#148.5 MHz Clock
create_clock -period 6.734 -waveform {0.000 3.367} [get_ports USER_MGT_SI570_CLOCK1_C_P]

####################################
# syncing from r/tx_outclk[0-2] to axi4lite domain
####################################	-- baoshan: fixed xdc including the value > 100Mhz
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -filter REF_PIN_NAME=~*RXOUTCLK -of_objects [get_cells -hierarchical *GTHE4_CHANNEL_PRIM_INST]]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter name=~*/zynq_us/inst/pl_clk0]] 9.900
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -filter REF_PIN_NAME=~*TXOUTCLK -of_objects [get_cells -hierarchical *GTHE4_CHANNEL_PRIM_INST]]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter name=~*/zynq_us/inst/pl_clk0]] 9.900
####################################
# syncing from axi4lite to r/tx_outclk[0-2]
####################################	-- baoshan: fixed xdc
set_max_delay -datapath_only -from [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter name=~*/zynq_us/inst/pl_clk0]] -to [get_clocks -of_objects [get_pins -filter REF_PIN_NAME=~*RXOUTCLK -of_objects [get_cells -hierarchical *GTHE4_CHANNEL_PRIM_INST]]] 3.267
set_max_delay -datapath_only -from [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter name=~*/zynq_us/inst/pl_clk0]] -to [get_clocks -of_objects [get_pins -filter REF_PIN_NAME=~*TXOUTCLK -of_objects [get_cells -hierarchical *GTHE4_CHANNEL_PRIM_INST]]] 3.267

####################################
# syncing from sys_clk(300Mhz) to axi4lite_clk domain
####################################	-- baoshan: fixed xdc
set_max_delay -datapath_only -from [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter name=~*/zynq_us/inst/pl_clk1]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter name=~*/zynq_us/inst/pl_clk0]] 9.900

####################################
# syncing from axi4lite_clk(100Mhz) to sys_clk(300Mhz)
####################################	-- baoshan: fixed xdc
set_max_delay -datapath_only -from [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter name=~*/zynq_us/inst/pl_clk0]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter name=~*/zynq_us/inst/pl_clk1]] -0.100

##START# Include if CPLL is activated
#set_max_delay $max_delay_clk_27M -datapath_only # -from [get_clocks uhdsdi_demo/v_uhdsdi_support_CSL/v_uhdsdi_CL/uhdsdi_gtwiz_i*GTHE3_CHANNEL_PRIM_INST/TXOUTCLK] # -to [get_clocks clk_27M]
##END# Include if CPLL is activated

##START# Include if CPLL is activated
#set_max_delay $max_delay_txusrclk -datapath_only # -from [get_clocks clk_27M] # -to [get_clocks uhdsdi_demo/v_uhdsdi_support_CSL/v_uhdsdi_CL/uhdsdi_gtwiz_i*GTHE3_CHANNEL_PRIM_INST/TXOUTCLK]
##END# Include if CPLL is activated

#
# Create a hierarchical clock to constrain the timing of the NI-DRU and EDH. This
# module is driven by rx0_outclk, but is only active when that clock is 148.5
# MHz and never when it is 297 MHz.
#
## SDI Wrapper Support Ch0	-- baoshan: fixed xdc
set_property KEEP_HIERARCHY true [get_cells -hierarchical -filter {name =~*/compact_gt_wrapper/compact_gt/uhdsdi_gt_0/inst/uhdsdi_ctrl_0/GEN_NIDRU.NIDRU}]
create_generated_clock -name nidru_clk0 -source [get_pins -hier -filter name=~*GTHE4_CHANNEL_PRIM_INST/RXOUTCLK] -divide_by 2 [get_pins -hier -filter name=~*GEN_NIDRU.NIDRU/Inst_dru/CLK]

#
# The 3 main clocks are asynchronous from each other.
#
##	baoshan: designer need to review this value
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -filter REF_PIN_NAME=~*RXOUTCLK -of_objects [get_cells -hierarchical *GTHE4_CHANNEL_PRIM_INST]]] -to [get_clocks -regexp {nidru_clk[0-9]}] 6.634
##	baoshan: fixed xdc
set_max_delay -datapath_only -from [get_clocks -regexp {nidru_clk[0-9]}] -to [get_clocks -of_objects [get_pins -filter REF_PIN_NAME=~*RXOUTCLK -of_objects [get_cells -hierarchical *GTHE4_CHANNEL_PRIM_INST]]] 3.267

##	baoshan: fixed xdc
#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins -filter {REF_PIN_NAME=~*RXOUTCLK} -of_objects [get_cells -hierarchical *GTHE4_CHANNEL_PRIM_INST]]] -group [get_clocks -of_objects [get_pins -filter {REF_PIN_NAME=~*TXOUTCLK} -of_objects [get_cells -hierarchical *GTHE4_CHANNEL_PRIM_INST]]] -group [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*/zynq_us/inst/pl_clk0}]] -group [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*/zynq_us/inst/pl_clk1}]] -group clk_27M




set_false_path -from [get_pins {uhdsdi_demo/i_bd/axi_interconnect_2/s01_couplers/s01_regslice/inst/r.r_pipe/m_payload_i_reg[89]/C}] -to [get_pins {uhdsdi_demo/i_bd/vcu_0/inst/VCU_i/PLVCUDECRDATA1[89]}]
