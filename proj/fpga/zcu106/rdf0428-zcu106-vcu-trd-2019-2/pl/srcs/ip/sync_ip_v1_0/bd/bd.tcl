#IP Integrator’s bd/bd.tcl
#cellPath: path to the cell instance


proc post_config_ip {cellPath otherInfo } {
#bd::send_msg -of $cellPath -type INFO -msg_id 17 -text ": "
}


proc init { cellPath otherInfo } {
#bd::send_msg -of $cellPath -type INFO -msg_id 17 -text ": from Init "
}

#changes for promote
#
proc propagate {cellPath otherInfo } {
#bd::send_msg -of $cellPath -type INFO -msg_id 17 -text ": from Propagate  ."

}

proc pre_propagate { cellPath otherInfo } {
#bd::send_msg -of $cellPath -type INFO -msg_id 17 -text ": from Pre-Propagate  ."
}

proc post_propagate {cellPath otherInfo} {
#bd::send_msg -of $cellPath -type INFO -msg_id 17 -text ": from Post Propogate  ."
}
