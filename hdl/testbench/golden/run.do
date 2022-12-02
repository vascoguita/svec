# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

vsim -quiet -t 10fs -L unisim work.main

set StdArithNoWarnings 1
set NumericStdNoWarnings 1

radix -hexadecimal

log -r /*

run -all
