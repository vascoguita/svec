files = [ "svec_top.vhd", "svec_top.ucf", "xvme64x_core.vhd" ]

fetchto = "../../ip_cores"

modules = {
    "git" : [ "git://ohwr.org/hdl-core-lib/general-cores.git" ],
    "svn" : [ "http://svn.ohwr.org/vme64x-core/trunk/hdl/vme64x-core/rtl" ]
    }
