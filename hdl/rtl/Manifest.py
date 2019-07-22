# User should define the variable svec_template_ucf

files = ["svec_template_regs.vhd",
         "svec_template_wr.vhd", "svec_template_common.ucf" ]

ucf_dict = {'ddr4': "svec_template_ddr4.ucf",
            'ddr5': "svec_template_ddr5.ucf",
            'wr':   "svec_template_wr.ucf",
            'led':  "svec_template_led.ucf",
            'gpio': "svec_template_gpio.ucf" }
for p in svec_template_ucf:
    f = ucf_dict.get(p, None)
    assert f is not None, "unknown name {} in 'svec_template_ucf'".format(p)
    files.append(f)
