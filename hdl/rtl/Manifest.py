# User should define the variable svec_template_ucf

files = ["svec_template_regs.vhd",
         "svec_template_wr.vhd", "svec_template_common.ucf" ]

if "ddr4" in svec_template_ucf:
    files.append("svec_template_ddr4.ucf")
if "ddr5" in svec_template_ucf:
    files.append("svec_template_ddr5.ucf")
