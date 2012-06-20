/*
 * A tool to program our soft-core (LM32) within the SVEC.
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
	int bus = -1, c;
	uint32_t lm32_base = 0x00000;
	void *card;


	while ((c = getopt (argc, argv, "b:c:")) != -1)
	{
		switch(c)
		{
		case 'b':
			sscanf(optarg, "%i", &bus);
			break;
		case 'c':
			sscanf(optarg, "%i", &lm32_base);
			break;
		default:
			fprintf(stderr,
				"Use: \"%s [-b slot] [-c lm32 base address] <lm32_program.bin>\"\n", argv[0]);
			fprintf(stderr,
				"By default, the first available SVEC is used and the LM32 is assumed at 0x%x.\n", lm32_base);
			exit(1);
		}
	}

	if (optind >= argc) {
		fprintf(stderr, "Expected binary name after options.\n");
		exit(1);
	}
    
        card = svec_open(bus);
	if(!card)
	{
	 	fprintf(stderr, "Can't detect a SVEC card under the given adress. Make sure a SVEC card is present in your PC and the driver is loaded.\n");
	 	exit(1);
	}

	fprintf(stderr,"Loading..\n");

	if(svec_load_lm32(card, argv[optind], lm32_base) < 0)
	{
	 	fprintf(stderr, "Loader failure.\n");
	 	exit(1);
	}

	svec_close(card);
	
	exit (0);
}
