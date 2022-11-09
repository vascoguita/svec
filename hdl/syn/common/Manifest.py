# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

# User should define the variable svec_base_ucf

files = [ "svec_base_common.ucf" ]

ucf_dict = {
    'ddr4': "svec_base_ddr4.ucf",
    'ddr5': "svec_base_ddr5.ucf",
    'wr':   "svec_base_wr.ucf",
    'led':  "svec_base_led.ucf",
    'gpio': "svec_base_gpio.ucf",
}

for p in svec_base_ucf:
    f = ucf_dict.get(p, None)
    assert f is not None, "unknown name {} in 'svec_base_ucf'".format(p)
    if p == 'ddr4' or p == 'ddr5':
        if 'svec_base_ddr_common.ucf' not in files:
            files.append('svec_base_ddr_common.ucf')
    files.append(f)
