#include <stdio.h>

main(int argc, char *argv[])
{
	FILE *f_in = fopen(argv[1], "rb");
	unsigned char c;	
	printf("@00\n");
	while(fread(&c,1,1,f_in) == 1)
		printf("%02X\n", c);
	fclose(f_in);
}