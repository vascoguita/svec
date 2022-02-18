# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

files = [
    "svec_base_regs.vhd",
    "svec_base_wr.vhd",
    "sourceid_svec_base_pkg.vhd",
]

try:
    # Assume this module is in fact a git submodule of a main project that
    # is in the same directory as general-cores...
    exec(open("../../../" + "/general-cores/tools/gen_sourceid.py").read(),
         None, {'project': 'svec_base'})
except Exception as e:
    import os
    print("Error: cannot generate source id file (pwd={})".format(os.getcwd()))
    raise
