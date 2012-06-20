/*
 * A tool to program the FPGA within the SPEC.
 *
 * Alessandro Rubini 2012 for CERN, GPLv2 or later.
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <getopt.h>

#include "sveclib.h"

int main(int argc, char **argv)
{
	int bus = -1,  c;
	void *card;

	while ((c = getopt (argc, argv, "b:")) != -1)
	{
		switch(c)
		{
		case 'b':
			sscanf(optarg, "%i", &bus);
			break;
		default:
			fprintf(stderr,
				"Use: \"%s -b slot <fpga_bitstream.bin>\"\n", argv[0]);
			exit(1);
		}
	}

	if (optind >= argc) {
		fprintf(stderr, "Expected binary name after options.\n");
		exit(1);
	}
	if(bus < 0)
	{
	    fprintf(stderr, "You must specify the slot number.\n");
	    return -1;
	}
    
    card = svec_open(bus);
	if(!card)
	{
	 	fprintf(stderr, "Can't detect a SVEC card under the given adress. Make sure a SVEC card is present in your PC and the driver is loaded.\n");
	 	exit(1);
	}

	if(svec_load_bitstream(card, argv[optind]) < 0)
	{
	 	fprintf(stderr, "Loader failure.\n");
	 	exit(1);
	}

	svec_close(card);
	
	exit (0);
}
