#!/usr/bin/python
# Matthieu Cattin 2012

import re, sys

# Export netlist from Altium Designer in "Calay" format

NETLIST_FILENAME = "svec_v0.net"
UCF_FILENAME = "svec_v0.ucf"

PART_DESIGNATOR = "IC19"

IGNORED_NETNAMES = ["GND", "P3V3", "P2V5","P1V5", "P1V2", "P1V8",
                    "MTG_AVC_A", "MTG_AVC_B", "VREF_DDR3",
                    "FMC1_VREFAM2C", "FMC2_VREFAM2C"]

IOSTANDARD = "LVCMOS33"


filename = raw_input("Enter the input netlist filename (Must be Calay format!): ")
if filename != "":
    NETLIST_FILENAME = filename

try:
    net = open(NETLIST_FILENAME,"r")
    print "%s netlist opened." % NETLIST_FILENAME
except:
    print "ERROR %s file doesn't exist!" % NETLIST_FILENAME
    sys.exit()

filename = raw_input("Enter the output .ucf filename: ")
if filename != "":
    UCF_FILENAME = filename

try:
    ucf = open(UCF_FILENAME+".raw","w")
    print "%s .ucf opened." % UCF_FILENAME
except:
    print "ERROR %s file doesn't exist!" % UCF_FILENAME

part = raw_input("Enter the part designator: ")
if part != "":
    PART_DESIGNATOR = part

print "The part %s has been selected for ucf generation." % PART_DESIGNATOR


pin_cnt = 0

# Iterate over lines in netlist file
for line in net:
    # Remove non-alphanumerical char
    line = re.sub(r'[^\w]', ' ', line)
    # Split line into strings
    ln = line.split()
    for s in ln:
        # Look for lines containing the given part designator
        if (ln[0] != s) and (PART_DESIGNATOR in s) and not(ln[0] in IGNORED_NETNAMES) and not(re.match("Net", ln[0])):
            pin_cnt += 1
            #print "%s %s %s" % (s, ln[0], ln[ln.index(s)+1])
            ucf.write("NET \""+ln[0].lower()+"\" LOC = "+ln[ln.index(s)+1]+";\n")

if pin_cnt == 0:
    print " Sorry, no pin found in %s" % (PART_DESIGNATOR)
if pin_cnt == 1:
    print " => %d pin found in %s" % (pin_cnt, PART_DESIGNATOR)
else:
    print " => %d pins found in %s" % (pin_cnt, PART_DESIGNATOR)


yesno = ""
while (yesno.lower() != 'y') and (yesno.lower() != 'n'):
    yesno = raw_input("Do you want to generate default IOSTANDARD [y/n]: ")

if yesno == 'y':
    net = open(NETLIST_FILENAME,"r")
    ucf.write("\n\n\n\n")
    # Iterate over lines in netlist file
    for line in net:
        # Remove non-alphanumerical char
        line = re.sub(r'[^\w]', ' ', line)
        # Split line into strings
        ln = line.split()
        for s in ln:
            # Look for lines containing the given part designator
            if (ln[0] != s) and (PART_DESIGNATOR in s) and not(ln[0] in IGNORED_NETNAMES) and not(re.match("Net", ln[0])):
                # print "%s %s %s" % (s, ln[0], ln[ln.index(s)+1])
                ucf.write("NET \""+ln[0].lower()+"\" IOSTANDARD = \""+ IOSTANDARD +"\";\n")

net.close()
ucf.close()
