files = ["bicolor_led_ctrl_pkg.vhd",
         "bicolor_led_ctrl.vhd",
         "wb_addr_decoder.vhd",
         "svec_afpga_top.vhd",
         "csr.vhd",
         "svec_v0_afpga.ucf"]

fetchto = "ip_cores"

modules = {
    "git"   : [ "git://ohwr.org/hdl-core-lib/general-cores.git" ],
    "svn"   : [ "http://svn.ohwr.org/vme64x-core/trunk/hdl/vme64x-core/rtl",
                "http://svn.ohwr.org/ddr3-sp6-core/trunk/hdl" ]
    }
