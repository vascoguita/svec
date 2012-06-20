/* A simple console for accessing the SVEC virtual UART (i.e. for communicating with the WR Core shell
   from a Linux terminal. */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <getopt.h>
#include <errno.h>

#include "sveclib.h"

static void *card;

static int transfer_byte(int from, int is_control) {
	char c;
	int ret;
	do {
		ret = read(from, &c, 1);
	} while (ret < 0 && errno == EINTR);
	if(ret == 1) {
		if(is_control) {
			if(c == '\x01') { // C-a
				return -1;
			} 
		}
		svec_vuart_tx(card, &c, 1);
	} else {
		fprintf(stderr, "\nnothing to read. probably port disconnected.\n");
		return -2;
	}
	return 0;
}


void term_main(int keep_term)
{
	struct termios oldkey, newkey;       //place tor old and new port settings for keyboard teletype
	int need_exit = 0;

	fprintf(stderr, "[press C-a to exit]\n");

	if(!keep_term) {
		tcgetattr(STDIN_FILENO,&oldkey);
		newkey.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
		newkey.c_iflag = IGNPAR;
		newkey.c_oflag = 0;
		newkey.c_lflag = 0;
		newkey.c_cc[VMIN]=1;
		newkey.c_cc[VTIME]=0;
		tcflush(STDIN_FILENO, TCIFLUSH);
		tcsetattr(STDIN_FILENO,TCSANOW,&newkey);
	}
	while(!need_exit) {
		fd_set fds;
		int ret;
		char rx;
		struct timeval tv = {0, 10000};
		
		FD_ZERO(&fds);
		FD_SET(STDIN_FILENO, &fds);

		ret = select(STDIN_FILENO+1, &fds, NULL, NULL, &tv);
		if(ret == -1) {
			perror("select");
		} else if (ret > 0) {
			if(FD_ISSET(STDIN_FILENO, &fds)) {
				need_exit = transfer_byte(STDIN_FILENO, 1);
			}
		}

		while((svec_vuart_rx(card, &rx, 1)) == 1)
			fprintf(stderr,"%c", rx);

	}

	if(!keep_term)
		tcsetattr(STDIN_FILENO,TCSANOW,&oldkey);
}

int main(int argc, char **argv)
{
	int bus = -1, c;
	uint32_t vuart_base = 0x20500;
	int keep_term = 0;

	while ((c = getopt (argc, argv, "b:u:k")) != -1)
	{
		switch(c)
		{
		case 'b':
			sscanf(optarg, "%i", &bus);
			break;
		case 'u':
			sscanf(optarg, "%i", &vuart_base);
			break;
		case 'k':
			keep_term = 1;
			break;
		default:
			fprintf(stderr,
				"Use: \"%s [-b slot] [-u VUART base] [-k]\"\n", argv[0]);
			fprintf(stderr,
				"By default, the VUART is assumed at 0x%x.\n \
-k option keeps the terminal config unchanged.\n", vuart_base);
			exit(1);
		}
	}

	if(bus < 0)
	{
		fprintf(stderr, "Missing slot number.\n");
		return -1;
	}

   card = svec_open(bus);

	if(!card)
	{
	 	fprintf(stderr, "Can't detect a SVEC card under the given adress. Make sure a SVEC card is present in your PC and the driver is loaded.\n");
		return -1;
	}
	

	svec_vuart_init(card, vuart_base);
	term_main(keep_term);
	svec_close(card);

	return 0;
}
