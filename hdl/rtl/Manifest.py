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
    print("Error: cannot generate source id file")
    raise
