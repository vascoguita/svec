# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

target = "xilinx"
action = "synthesis"

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
  fetchto = "../../ip_cores"

# Ideally this should be done by hdlmake itself, to allow downstream Manifests to be able to use the
# fetchto variable independent of where those Manifests reside in the filesystem.
import os
fetchto = os.path.abspath(fetchto)

syn_device = "xc6slx9"
syn_grade = "-2"
syn_package = "ftg256"
syn_top = "svec_sfpga_top"
syn_project = "svec_sfpga.xise"
syn_tool = "ise"

files = [ "svec_sfpga_top.ucf" ]

modules = {
    "local" : [
        "../../top/sfpga_bootloader",
    ],
  "git" : [
      "https://ohwr.org/project/general-cores.git",
  ],
}
