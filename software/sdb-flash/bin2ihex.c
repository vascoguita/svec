/*
*   bin2ihex: convert binary files to Intel hex files
*   93/03/08 john h. dubois iii (john@armory.com)
*   94/07/05 Andy Rabagliati    (andyr@wizzy.com)
*            Added Intel Extended address record
*            port to PC  (unsigned longs everywhere)
*/

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#ifndef __MSDOS__
#include <unistd.h>
#endif

#ifndef _NO_PROTOTYPE
unsigned long ProcFile(int InFile, int BytesPerRec, unsigned long Origin,
int Dots, int Extended);
char *bin2ihex(unsigned char *In, unsigned char *Out, int NBytes,
unsigned long Address);
#endif

#define	b2h(b,p) *((p)++) = HexTable[(b) >> 4], *((p)++) = HexTable[(b) & 0xF]
#define MAXBYTES 255	/* Intel 00 record can only store 255 bytes */
#define MAXLINE (MAXBYTES * 2 + 12)
#ifdef __MSDOS__
#   define OPEN_FLAGS (O_RDONLY | O_BINARY)
#else
#   define OPEN_FLAGS O_RDONLY
#endif

char *HexTable = "0123456789ABCDEF";
char *FILENAME;		/* File being read, for use by error messages */
char *Name;	/* Name of this process, for use by help & error messages */
char *Comment = "@(#) bin2ihex 1.1 96/07/03";

main(int argc, char *argv[])
{
    extern char *optarg;
    extern int optind;
    int Quiet = 0;	/* Do not print status messages */
    char c;		/* Option being processed */
    int InFile;		/* file descriptor being read from */
    char *OutFileName = "stdout";	/* Output file name */
    char *Usage = 
    "Usage: %s [-ehq] [-o outfile] [-g origin] [-b bytes/record] [infile]\n";
    char *ptr;		/* For checking result of strtol() */
    int BytesPerRec = 16;	/* Number of bytes per record to write */
    unsigned long Written;	/* Number of bytes processed */
    unsigned long Origin = 0;	/* Origin of output */
    int Dots = 0;	/* Whether to print a dot on stderr for every record */
    int Extended = 0;	/* Write extended Intel hex records? */

    if (Name = strrchr(argv[0],'/'))
	Name++;
    else
	Name = argv[0];
    while ((c = getopt(argc, argv, "dehqb:g:o:")) != -1)
	switch (c) {
	case 'd':
	    Dots = 1;
	    break;
	case 'e':
	    Extended = 1;
	    break;
	case 'g':
	    Origin = (unsigned long) strtol(optarg,&ptr,0);
	    if (((long) Origin) < 0 || ptr == optarg) {
		fprintf(stderr,"%s: \"%s\": Invalid origin.\n",Name,optarg);
		exit(1);
	    }
	    break;
	case 'b':
	    BytesPerRec = strtol(optarg,&ptr,0);
	    if (BytesPerRec < 1 || BytesPerRec > MAXBYTES || ptr == optarg) {
		fprintf(stderr,"%s: \"%s\": Invalid number of bytes/record.\n"\
		"Must be between 1 and %d.\n",Name,optarg,MAXBYTES);
		exit(1);
	    }
	    break;
	case 'q':
	    Quiet = 1;
	    break;
	case 'o':
	    OutFileName = optarg;
	    if (!freopen(OutFileName,"w",stdout)) {
		fprintf(stderr,"%s: Could not open output file \"%s\": ",
		Name,OutFileName);
		perror("");
		exit(2);
	    }
	    break;
	case 'h':
	    printf(
	    "%s: convert binary file to Intel-hex format records.\n",Name);
	    printf(Usage,Name);
	    printf(
"-g <origin>: Make addresses specified in output records start at <origin>.\n"\
"   <origin> may be given in decimal, octal, or hex by using C base syntax.\n"\
"   The default origin is 0.\n"\
"-o <outfile>: Write output to <outfile>.\n"\
"   The default is to write to the standard output.\n"\
"-b <bytes-per-record>: write <bytes-per-record> bytes (encoded in hex\n"\
"   format) on each line.  The line length will be <bytes-per-record>*2 + 11\n"\
"   characters (plus a newline).\n"\
"   <bytes-per-record> must be between 1 and %d.\n"\
"-d: Print a dot on stderr for every record processed.\n"\
"-e: Write extended Intel hex reords.  Addresses may be up to 0xFFFFF.\n"\
"-q: Quiet operation: no status messages are printed.  If -q is not given,\n"\
"    the total number of bytes processed is printed to stderr at completion.\n"\
"-h: Print this help information.\n"\
"\n"\
"If no input file is given, input is read from the standard input.\n"\
,MAXBYTES);
	    exit(0);
	case '?':
	    fprintf(stderr,"%s: Invalid flag: '%c'.\n",Name,c);
	    fprintf(stderr,Usage,Name);
	    exit(1);
	}
    switch (argc - optind) {
    case 0:
	InFile = 0;
	FILENAME = "stdin";
	break;
    case 1:
	if ((InFile = open(argv[optind],OPEN_FLAGS)) == -1) {
	    fprintf(stderr,"%s: Could not open input file \"%s\": ",
	    Name,argv[optind]);
	    perror("");
	    exit(2);
	}
	FILENAME = argv[optind];
	break;
    default:
	fprintf(stderr,"%s: Too many arguments.\n",Name);
	fprintf(stderr,Usage,Name);
	exit(2);
    }
    Written = ProcFile(InFile,BytesPerRec,Origin,Dots,Extended);
    /* andyr added this.  01 = end of file?  For now, print only if Extended */
    if (Extended)
	puts(":00000001FF\n");
    if (!Quiet) {
	if (Dots)
	    fputc('\n',stderr);
	fprintf(stderr,"%lu bytes written in %lu records.\n",Written,
	(Written + BytesPerRec - 1) / BytesPerRec);
    }
}

/* Eaddr from andyr */
char *Eaddr( unsigned char *OutBuf, unsigned long Eaddress)
{
    unsigned Checksum;  /* Checksum of the record */
    unsigned char *Out = OutBuf; /* Position in OutBuf being written to */

    *(Out++) = ':';
    *(Out++) = '0';
    *(Out++) = '2';

    *(Out++) = '0';
    *(Out++) = '0';
    *(Out++) = '0';
    *(Out++) = '0';

    *(Out++) = '0';
    *(Out++) = '2';
    b2h(Eaddress >> 12,Out);
    b2h((Eaddress >> 4) & 0xFF, Out);
    Checksum = 2 + 2 + (Eaddress >> 12) + (Eaddress >> 4);
    Checksum = (-Checksum & 0xFF);
    b2h(Checksum,Out);
    *(Out++) = '\0';
    return (char *) OutBuf;
}

/*
    Convert a binary file to Intel hex format.
    Return value: the number of bytes converted & written.
*/
unsigned long ProcFile(int InFile, int BytesPerRec, unsigned long Origin,
int Dots, int Extended)
{
    unsigned char InBuf[MAXLINE/2];	/* Input data buffer */
    unsigned char OutBuf[MAXLINE];	/* Output buffer */
    int InBytes;		/* Number of bytes actually read from fd */
    unsigned long Address = Origin;	/* Record address */
    unsigned long Eaddress = 0UL;
    unsigned long Count = 0UL;
    unsigned long MaxOffset = Extended ? 0xFFFFFUL : 0xFFFFUL;

    if (Extended)
	puts(Eaddr(OutBuf, Eaddress));
    while ((InBytes = read(InFile,InBuf,BytesPerRec)) > 0) {
	Count += InBytes;
	if ((Address + InBytes) > MaxOffset) {
	    if (Dots)
		fputc('\n',stderr);
	    fprintf(stderr,"%s: Record address exceeded 0x%X.\n",
	    Name,MaxOffset);
	    break;
	}
	if (Extended && (Address + InBytes) > 0xFFFFUL) {
	    Eaddress = Address & 0xFFFF0;
	    Address = Address - Eaddress;
	    puts(Eaddr(OutBuf, Eaddress));
	}
	puts(bin2ihex(InBuf,OutBuf,InBytes,Address));
	Address += InBytes;
	if (Dots)
	    write(2,".",1);
    }
    if (InBytes == -1) {
	if (Dots)
	    fputc('\n',stderr);
	fprintf(stderr,"%s: Error reading file \"%s\": ",Name,FILENAME);
	perror("");
    }
    return Count;
}

/*
*   Format of an Intel hex record:
*   :nnaaaa00dd....ddss
*   nn: Number of data bytes
*   aaaa: Address
*   dd: data bytes
*   ss: 0-sum corrective checksum for all bytes on line.
*/
/*
*   bin2ihex: convert binary data to an Intel hex record.
*   Input variables:
*   In is the input data.
*   Address is the data address for the record.
*   Output variables:
*   Out is a buffer to store the record in.
*   NBytes is the number of bytes to translate.
*   Return value: None.
*/
char *bin2ihex(unsigned char *In, unsigned char OutBuf[], int NBytes, 
unsigned long Address)
{
    int i;
    unsigned Checksum;		/* Checksum of the record */
    unsigned char *Out = OutBuf;  /* Position in OutBuf being written to */

    *(Out++) = ':';
    b2h(NBytes,Out);
    b2h(Address >> 8,Out);
    b2h(Address & 0xFF,Out);
    *(Out++) = '0';
    *(Out++) = '0';
    Checksum = NBytes + (Address >> 8) + Address;
    for (i = 0; i < NBytes; i++) {
	b2h(*In,Out);
	Checksum += *(In++);
    }
    Checksum = (-Checksum & 0xFF);
    b2h(Checksum,Out);
    *(Out++) = '\0';
    return (char *) OutBuf;
}
