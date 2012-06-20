vlog -sv main.sv +incdir+. +incdir+../../sim/wb +incdir+../../sim/vme64x_bfm +incdir+../../sim
vsim work.main -voptargs=+acc

set StdArithNoWarnings 1
set NumericStdNoWarnings 1

do wave.do
run 30us