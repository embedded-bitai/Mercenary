# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST   } {
  #source_ipfile "bd/bd.tcl"

  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Configuration"]
  set enc_dec [ipgui::add_group $IPINST -parent $Page_0 -name "ENC_DEC_Configuration" -layout horizontal]  
     ipgui::add_param $IPINST -name "ENABLE_ENC_DEC" -parent ${enc_dec} -widget comboBox -layout horizontal
  set vid_chan [ipgui::add_group $IPINST -parent $Page_0 -name "Number_Of_Channel" -layout vertical]  
     ipgui::add_param $IPINST -name "NO_OF_ENC_CHAN" -parent ${vid_chan} -widget comboBox -layout horizontal
     ipgui::add_param $IPINST -name "NO_OF_DEC_CHAN" -parent ${vid_chan} -widget comboBox -layout horizontal
  set consumers [ipgui::add_group $IPINST -parent $Page_0 -name "Number_Of_Consumers" -layout horizontal]  
     ipgui::add_param $IPINST -name "NO_OF_CONSUMERS" -parent ${consumers} -widget comboBox -layout horizontal
#  set prod_config [ipgui::add_group $IPINST -parent $Page_0 -name "Producer_Configuration" -layout horizontal]  
#     ipgui::add_param $IPINST -name "ENABLE_PROD_0" -parent ${prod_config} -widget checkBox -layout horizontal
##     ipgui::add_param $IPINST -name "PORT_PROD_0" -parent ${prod_config} -widget comboBox -layout horizontal
#     ipgui::add_row $IPINST -parent $prod_config
#     ipgui::add_param $IPINST -name "ENABLE_PROD_1" -parent ${prod_config} -widget checkBox -layout horizontal
##     ipgui::add_param $IPINST -name "PORT_PROD_1" -parent ${prod_config} -widget comboBox -layout horizontal
#     ipgui::add_row $IPINST -parent ${prod_config}
#     ipgui::add_param $IPINST -name "ENABLE_PROD_2" -parent ${prod_config} -widget checkBox -layout horizontal
##     ipgui::add_param $IPINST -name "PORT_PROD_2" -parent ${prod_config} -widget comboBox -layout horizontal
#     ipgui::add_row $IPINST -parent ${prod_config}
#     ipgui::add_param $IPINST -name "ENABLE_PROD_3" -parent ${prod_config} -widget checkBox -layout horizontal
##     ipgui::add_param $IPINST -name "PORT_PROD_3" -parent ${prod_config} -widget comboBox -layout horizontal
#     ipgui::add_row $IPINST -parent ${prod_config}

#  set cons_config [ipgui::add_group $IPINST -parent $Page_0 -name "Consumer_Configuration" -layout horizontal ]  
#     ipgui::add_param $IPINST -name "ENABLE_CONS_0" -parent ${cons_config} -widget checkBox -layout horizontal
##     ipgui::add_param $IPINST -name "PORT_CONS_0" -parent ${cons_config} -widget comboBox -layout horizontal
#     ipgui::add_row $IPINST -parent ${cons_config}
#     ipgui::add_param $IPINST -name "ENABLE_CONS_1" -parent ${cons_config} -widget checkBox -layout horizontal
##     ipgui::add_param $IPINST -name "PORT_CONS_1" -parent ${cons_config} -widget comboBox -layout horizontal
#     ipgui::add_row $IPINST -parent ${cons_config}

}

#proc init_gui {IPINST MODELPARAM_VALUE.ENABLE_ENC_DEC_HDL PARAM_VALUE.ENABLE_ENC_DEC PARAM_VALUE.NO_OF_ENC_CHAN PARAM_VALUE.NO_OF_DEC_CHAN}{
#
#        set_property visible true [ipgui::get_guiparamspec NO_OF_ENC_CHAN -of $IPINST]       
#		set_property visible false [ipgui::get_guiparamspec NO_OF_DEC_CHAN -of $IPINST]
#}


proc update_MODELPARAM_VALUE.ENABLE_ENC_DEC_HDL {MODELPARAM_VALUE.ENABLE_ENC_DEC_HDL  PARAM_VALUE.ENABLE_ENC_DEC PARAM_VALUE.NO_OF_ENC_CHAN PARAM_VALUE.NO_OF_DEC_CHAN IPINST } {
   set ENABLE_ENC_DEC [get_property value ${PARAM_VALUE.ENABLE_ENC_DEC}]
   set NO_OF_ENC_CHAN [get_property value ${PARAM_VALUE.NO_OF_ENC_CHAN}]
   set NO_OF_DEC_CHAN [get_property value ${PARAM_VALUE.NO_OF_DEC_CHAN}]
   # If Encoder 
   if { $ENABLE_ENC_DEC == 0 } {
     send_msg INFO 306 "---------Encoder mode----------"
        set_property value 0 ${MODELPARAM_VALUE.ENABLE_ENC_DEC_HDL} 
        set_property  enabled true  ${PARAM_VALUE.NO_OF_ENC_CHAN} 
        set_property  enabled false  ${PARAM_VALUE.NO_OF_DEC_CHAN} 
       # set_property visible true [ipgui::get_guiparamspec NO_OF_ENC_CHAN -of $IPINST]
       # set_property visible false [ipgui::get_guiparamspec NO_OF_DEC_CHAN -of $IPINST]
        #set_property  visible true  ${PARAM_VALUE.NO_OF_ENC_CHAN}
        #set_property  visible false  ${PARAM_VALUE.NO_OF_DEC_CHAN}
   } else {
   #if decoder
        set_property value 1 ${MODELPARAM_VALUE.ENABLE_ENC_DEC_HDL} 
        set_property  enabled false  ${PARAM_VALUE.NO_OF_ENC_CHAN} 
        set_property  enabled true  ${PARAM_VALUE.NO_OF_DEC_CHAN} 
        #set_property visible false [ipgui::get_guiparamspec NO_OF_ENC_CHAN -of $IPINST]
        #set_property visible true [ipgui::get_guiparamspec NO_OF_DEC_CHAN -of $IPINST]
        #set_property  visible false  ${PARAM_VALUE.NO_OF_ENC_CHAN} 
        #set_property  visible true  ${PARAM_VALUE.NO_OF_DEC_CHAN} 
   }
}

proc update_MODELPARAM_VALUE.HDL_PORT_MM_P_0_EN { MODELPARAM_VALUE.HDL_PORT_MM_P_0_EN MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL MODELPARAM_VALUE.NO_OF_DEC_CHAN_HDL PARAM_VALUE.ENABLE_PROD_0 PARAM_VALUE.NO_OF_ENC_CHAN PARAM_VALUE.NO_OF_DEC_CHAN} {
   set NO_OF_ENC_CHAN [get_property value ${PARAM_VALUE.NO_OF_ENC_CHAN}]
   set NO_OF_DEC_CHAN [get_property value ${PARAM_VALUE.NO_OF_DEC_CHAN}]
   set ENABLE_PROD_0 [get_property value ${PARAM_VALUE.ENABLE_PROD_0}]
   if { $NO_OF_ENC_CHAN < 0 || $NO_OF_DEC_CHAN < 0 } {
      set_property  enabled false  ${PARAM_VALUE.ENABLE_PROD_0} 
      #set_property value 0 ${MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL} 
      set_property value 0 ${MODELPARAM_VALUE.NO_OF_DEC_CHAN_HDL} 
      set_property value 0 ${MODELPARAM_VALUE.HDL_PORT_MM_P_0_EN}
   } else {
      set_property  enabled false  ${PARAM_VALUE.ENABLE_PROD_0} 
      #set_property value 1 ${MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL} 
      set_property value 1 ${MODELPARAM_VALUE.NO_OF_DEC_CHAN_HDL} 
      set_property value 1 ${MODELPARAM_VALUE.HDL_PORT_MM_P_0_EN}
   }
}

proc update_MODELPARAM_VALUE.HDL_PORT_MM_P_1_EN { MODELPARAM_VALUE.HDL_PORT_MM_P_1_EN MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL PARAM_VALUE.ENABLE_ENC_DEC MODELPARAM_VALUE.NO_OF_DEC_CHAN_HDL PARAM_VALUE.ENABLE_PROD_1 PARAM_VALUE.NO_OF_ENC_CHAN  PARAM_VALUE.NO_OF_DEC_CHAN} {
   set ENABLE_ENC_DEC [get_property value ${PARAM_VALUE.ENABLE_ENC_DEC}]
   set NO_OF_ENC_CHAN [get_property value ${PARAM_VALUE.NO_OF_ENC_CHAN}]
   set NO_OF_DEC_CHAN [get_property value ${PARAM_VALUE.NO_OF_DEC_CHAN}]
   set ENABLE_PROD_1 [get_property value ${PARAM_VALUE.ENABLE_PROD_1}]
   if { ($ENABLE_ENC_DEC ==1 && $NO_OF_DEC_CHAN < 1) || ($ENABLE_ENC_DEC ==0 && $NO_OF_ENC_CHAN < 1)  } {
      set_property  enabled false  ${PARAM_VALUE.ENABLE_PROD_1} 
      set_property  value 0 ${PARAM_VALUE.ENABLE_PROD_1} 
      set_property value 0 ${MODELPARAM_VALUE.HDL_PORT_MM_P_1_EN}
   } else {
      set_property  enabled false  ${PARAM_VALUE.ENABLE_PROD_1} 
      #set_property value 2 ${MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL} 
      set_property value 2 ${MODELPARAM_VALUE.NO_OF_DEC_CHAN_HDL} 
      set_property  value 1 ${PARAM_VALUE.ENABLE_PROD_1} 
      set_property value 1 ${MODELPARAM_VALUE.HDL_PORT_MM_P_1_EN}
   }
}

proc update_MODELPARAM_VALUE.HDL_PORT_MM_P_2_EN { MODELPARAM_VALUE.HDL_PORT_MM_P_2_EN MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL PARAM_VALUE.ENABLE_PROD_2 PARAM_VALUE.ENABLE_ENC_DEC PARAM_VALUE.NO_OF_ENC_CHAN PARAM_VALUE.NO_OF_DEC_CHAN } {
   set NO_OF_ENC_CHAN [get_property value ${PARAM_VALUE.NO_OF_ENC_CHAN}]
   set NO_OF_DEC_CHAN [get_property value ${PARAM_VALUE.NO_OF_DEC_CHAN}]
   set ENABLE_PROD_2 [get_property value ${PARAM_VALUE.ENABLE_PROD_2}]
   set ENABLE_ENC_DEC [get_property value ${PARAM_VALUE.ENABLE_ENC_DEC}]
   if {$ENABLE_ENC_DEC == 1 || $NO_OF_ENC_CHAN < 2 } {
      set_property  enabled false  ${PARAM_VALUE.ENABLE_PROD_2} 
      set_property  value 0 ${PARAM_VALUE.ENABLE_PROD_2} 
      set_property value 0 ${MODELPARAM_VALUE.HDL_PORT_MM_P_2_EN}
   } else {
      set_property  enabled false  ${PARAM_VALUE.ENABLE_PROD_2} 
      #set_property value 3 ${MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL} 
      set_property  value 1 ${PARAM_VALUE.ENABLE_PROD_2} 
      set_property value 1 ${MODELPARAM_VALUE.HDL_PORT_MM_P_2_EN}
   }
}


proc update_MODELPARAM_VALUE.HDL_PORT_MM_P_3_EN { MODELPARAM_VALUE.HDL_PORT_MM_P_3_EN MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL PARAM_VALUE.ENABLE_PROD_3 PARAM_VALUE.ENABLE_ENC_DEC PARAM_VALUE.NO_OF_ENC_CHAN PARAM_VALUE.NO_OF_DEC_CHAN} {
   set NO_OF_ENC_CHAN [get_property value ${PARAM_VALUE.NO_OF_ENC_CHAN}]
   set NO_OF_DEC_CHAN [get_property value ${PARAM_VALUE.NO_OF_DEC_CHAN}]
   set ENABLE_PROD_3 [get_property value ${PARAM_VALUE.ENABLE_PROD_3}]
   set ENABLE_ENC_DEC [get_property value ${PARAM_VALUE.ENABLE_ENC_DEC}]
   if {$ENABLE_ENC_DEC == 1 || $NO_OF_ENC_CHAN < 3} {
      set_property  enabled false  ${PARAM_VALUE.ENABLE_PROD_3} 
      set_property  value 0 ${PARAM_VALUE.ENABLE_PROD_3} 
      set_property value 0 ${MODELPARAM_VALUE.HDL_PORT_MM_P_3_EN}
   } else {
          set_property  enabled false  ${PARAM_VALUE.ENABLE_PROD_3} 
          #set_property value 4 ${MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL} 
          set_property value 1 ${MODELPARAM_VALUE.HDL_PORT_MM_P_3_EN}
          set_property  value 1 ${PARAM_VALUE.ENABLE_PROD_3} 
   }
}



proc update_MODELPARAM_VALUE.HDL_PORT_MM_0_EN { MODELPARAM_VALUE.HDL_PORT_MM_0_EN  PARAM_VALUE.ENABLE_CONS_0 PARAM_VALUE.NO_OF_CONSUMERS } {
   set ENABLE_CONS_0 [get_property value ${PARAM_VALUE.ENABLE_CONS_0}]
   set NO_OF_CONSUMERS [get_property value ${PARAM_VALUE.NO_OF_CONSUMERS}]
   send_msg INFO 306 "--------in consumer 0----------" 
   if {$ENABLE_CONS_0 == "false" || $ENABLE_CONS_0 == "FALSE" || $NO_OF_CONSUMERS < 0} {
      set_property value 0 ${MODELPARAM_VALUE.HDL_PORT_MM_0_EN}
   } else {
      set_property value 1 ${MODELPARAM_VALUE.HDL_PORT_MM_0_EN}
   }
}

proc update_MODELPARAM_VALUE.HDL_PORT_MM_1_EN { MODELPARAM_VALUE.HDL_PORT_MM_1_EN  PARAM_VALUE.ENABLE_CONS_1 PARAM_VALUE.NO_OF_CONSUMERS } {
   set ENABLE_CONS_1 [get_property value ${PARAM_VALUE.ENABLE_CONS_1}]
   set NO_OF_CONSUMERS [get_property value ${PARAM_VALUE.NO_OF_CONSUMERS}]
   send_msg INFO 306 "--------in consumer 1----------" 
   if {$ENABLE_CONS_1 == "false" || $ENABLE_CONS_1 == "FALSE" || $NO_OF_CONSUMERS < 1} {
      set_property value 0 ${MODELPARAM_VALUE.HDL_PORT_MM_1_EN}
   } else {
      set_property value 1 ${MODELPARAM_VALUE.HDL_PORT_MM_1_EN}
   }
}

proc update_MODELPARAM_VALUE.HDL_PORT_MST_MM_0_EN { MODELPARAM_VALUE.HDL_PORT_MST_MM_0_EN  PARAM_VALUE.ENABLE_CONS_0  PARAM_VALUE.NO_OF_CONSUMERS } {
   set ENABLE_CONS_0 [get_property value ${PARAM_VALUE.ENABLE_CONS_0}]
   set NO_OF_CONSUMERS [get_property value ${PARAM_VALUE.NO_OF_CONSUMERS}]
   if {$ENABLE_CONS_0 == "false" || $ENABLE_CONS_0 == "FALSE" || $NO_OF_CONSUMERS < 0} {
      set_property value 0 ${MODELPARAM_VALUE.HDL_PORT_MST_MM_0_EN}
   } else {
      set_property value 1 ${MODELPARAM_VALUE.HDL_PORT_MST_MM_0_EN}
   }
}


proc update_MODELPARAM_VALUE.HDL_PORT_MST_MM_1_EN { MODELPARAM_VALUE.HDL_PORT_MST_MM_1_EN  PARAM_VALUE.ENABLE_CONS_1 PARAM_VALUE.NO_OF_CONSUMERS  } {
   set ENABLE_CONS_1 [get_property value ${PARAM_VALUE.ENABLE_CONS_1}]
   set NO_OF_CONSUMERS [get_property value ${PARAM_VALUE.NO_OF_CONSUMERS}]
   if {$ENABLE_CONS_1 == "false" || $ENABLE_CONS_1 == "FALSE" || $NO_OF_CONSUMERS < 1} {
      set_property value 0 ${MODELPARAM_VALUE.HDL_PORT_MST_MM_1_EN}
   } else {
      set_property value 1 ${MODELPARAM_VALUE.HDL_PORT_MST_MM_1_EN}
   }
}


#--------------------------------------
#no_of_consumer condition to print to HDL paramter added by pruthvi 25may_night: 

proc update_MODELPARAM_VALUE.NO_OF_CONSUMERS_HDL { MODELPARAM_VALUE.NO_OF_CONSUMERS_HDL PARAM_VALUE.NO_OF_CONSUMERS } {
   set no_of_consumers [get_property value ${PARAM_VALUE.NO_OF_CONSUMERS}]
   set no_of_consumers_hdl [get_property value ${MODELPARAM_VALUE.NO_OF_CONSUMERS_HDL}]
   if { $no_of_consumers == 0 } {
       set_property value 1 ${MODELPARAM_VALUE.NO_OF_CONSUMERS_HDL}
	  } else {
		  set_property value 2 ${MODELPARAM_VALUE.NO_OF_CONSUMERS_HDL}
	  }	
}

proc update_MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL { MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL PARAM_VALUE.NO_OF_ENC_CHAN } {
   set no_of_channel [get_property value ${PARAM_VALUE.NO_OF_ENC_CHAN}]
   set no_of_channel [expr $no_of_channel + 1]
   send_msg INFO 201 " sync_ip number of encoder channel .. $no_of_channel "
   set_property value $no_of_channel ${MODELPARAM_VALUE.NO_OF_ENC_CHAN_HDL}
}

