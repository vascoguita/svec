files = [ "svec_sfpga_top.vhd", "svec_sfpga_top.ucf" ]

fetchto = "../../ip_cores"

modules = {
    "local" : ["../../rtl" ],
    "git" : [ "git://ohwr.org/hdl-core-lib/general-cores.git" ]
    }
