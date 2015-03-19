
/*
 * Copyright (C) 2013 CERN (www.cern.ch)
 * Author: Tomasz Włostowski <tomasz.wlostowski@cern.ch>
 *
 * Released according to the GNU GPL, version 2 or any later version.
 *
 * svec-flasher: a trivial VME-SPI flasher application.
 */

#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <libvmebus.h>
//#include <libsdbfs.h>

#include "sxldr_regs.h"

#define BOOTLOADER_BASE 0x70000
#define BOOTLOADER_VERSION 2
#define BOOTLOADER_BITSTREAM_BASE 0x100000
#define BOOTLOADER_SDB_BASE 0x600000

#define ID_M25P128 0x202018

#define FLASH_PAGE_SIZE 256
#define FLASH_SECTOR_SIZE 0x40000
#define FLASH_SIZE 0x1000000

/* M25Pxxx SPI flash commands */
#define FLASH_WREN 0x06
#define FLASH_WRDI 0x04
#define FLASH_RDID 0x9F
#define FLASH_RDSR 0x05
#define FLASH_WRSR 0x01
#define FLASH_READ 0x03
#define FLASH_FAST_READ 0x0B
#define FLASH_PP 0x02
#define FLASH_SE 0xD8
#define FLASH_BE 0xC7

/* SDB filesystem header. Fixed for the time being, the final version should simply use libsdbfs. */
const uint8_t sdb_header[] = {
	0x53, 0x44, 0x42, 0x2d, 0x00, 0x03, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x60, 0x00, 0xc0,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xce, 0x42, 0x00, 0x00, 0x5f, 0xec,
	0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2e, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x2c, 0x13, 0xe9, 0x46, 0x69, 0x6c, 0x65, 0x44, 0x61, 0x74, 0x61,
	0x61, 0x66, 0x70, 0x67, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
	0x61, 0x66, 0x70, 0x67, 0x61, 0x2e, 0x62, 0x69, 0x6e, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x01, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x33, 0x93, 0x46, 0x69, 0x6c, 0x65,
	0x44, 0x61, 0x74, 0x61, 0x62, 0x6f, 0x6f, 0x74, 0x00, 0x00, 0x00, 0x01,
	0x00, 0x00, 0x00, 0x00, 0x62, 0x6f, 0x6f, 0x74, 0x6c, 0x64, 0x72, 0x2e,
	0x62, 0x69, 0x6e, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x01
};

struct vme_mapping map;
void *vme_va;

void release_vme()
{
	vme_unmap(&map, 1);
}

void init_vme(int slot)
{
	memset(&map, 0, sizeof(struct vme_mapping));
	map.am = 0x2f;
	map.data_width = 32;
	map.sizel = 0x1000;
	map.vme_addrl = slot * 0x80000 + BOOTLOADER_BASE;

	if ((vme_va = vme_map(&map, 1)) == NULL) {
		fprintf(stderr, "Could not map VME CSR space at 0x%08x\n",
			map.vme_addrl);
		exit(1);
	}
	atexit(release_vme);
}

static void csr_writel(uint32_t data, uint32_t addr)
{
	*(volatile uint32_t *)(vme_va + addr) = htonl(data);
}

static uint32_t csr_readl(uint32_t addr)
{
	return ntohl(*(volatile uint32_t *)(vme_va + addr));
}

void enter_bootloader()
{
	int i = 0;
	const uint32_t boot_seq[8] =
	    { 0xde, 0xad, 0xbe, 0xef, 0xca, 0xfe, 0xba, 0xbe };

	/* magic sequence: unlock bootloader mode, disable application FPGA */
	for (i = 0; i < 8; i++)
		csr_writel(boot_seq[i], SXLDR_REG_BTRIGR);
	if (csr_readl(SXLDR_REG_IDR) != 0x53564543) {	/* "SVEC" in hex */
		fprintf(stderr,
			"The bootloader is not responding. Are you sure the slot you've\n"
			"specified hosts a SVEC card? Is the SVEC's System FPGA programmed (the SFPGA\n"
			"Done' LED next to the fuses should be on).\n");
		exit(-1);
	}

	int version = SXLDR_CSR_VERSION_R(csr_readl( SXLDR_REG_CSR ));
	printf("Bootloader version: %d\n", version);
}

/* Tests the presence of the SPI master in the bootloader to check if we are running
   version > 1 (v1 does not have the version ID register) */
int spi_test_presence()
{
    csr_writel(	SXLDR_FAR_XFER | SXLDR_FAR_DATA_W(0xff),
		 SXLDR_REG_FAR);

    usleep(100000);
    
    uint32_t far = csr_readl(SXLDR_REG_FAR);

    /* transaction is not complete after so much time? no SPI... */
    return (far & SXLDR_FAR_READY);
}

void spi_cs(int cs)
{
	csr_writel(cs ? SXLDR_FAR_CS : 0, SXLDR_REG_FAR);
	usleep(1);
}

uint8_t spi_read8()
{
	uint32_t far;
	csr_writel(SXLDR_FAR_XFER | SXLDR_FAR_DATA_W(0xff) | SXLDR_FAR_CS,
		   SXLDR_REG_FAR);
	do {
		far = csr_readl(SXLDR_REG_FAR);
	} while (!(far & SXLDR_FAR_READY));

	return SXLDR_FAR_DATA_R(far);
}

void spi_write8(uint8_t data)
{
	uint32_t far;
	csr_writel(SXLDR_FAR_XFER | SXLDR_FAR_DATA_W(data) | SXLDR_FAR_CS,
		   SXLDR_REG_FAR);
	do {
		far = csr_readl(SXLDR_REG_FAR);
	} while (!(far & SXLDR_FAR_READY));
}

uint32_t flash_read_id()
{
	uint32_t val = 0;

	/* make sure the flash is in known state (idle) */
	spi_cs(0);
	usleep(10);
	spi_cs(1);
	usleep(10);

	spi_cs(1);
	spi_write8(FLASH_RDID);
	val = (spi_read8() << 16);
	val += (spi_read8() << 8);
	val += spi_read8();
	spi_cs(0);

	return val;
}

static void flash_wait_completion()
{
	int not_done = 1;

	while (not_done) {
		spi_cs(1);
		spi_write8(FLASH_RDSR);	/* Read Status register */
		uint8_t stat = spi_read8();
		not_done = (stat & 0x01);
		spi_cs(0);
	}
}

void flash_erase_sector(uint32_t addr)
{
	spi_cs(1);
	spi_write8(FLASH_SE);
	spi_write8((addr >> 16) & 0xff);
	spi_write8((addr >> 8) & 0xff);
	spi_write8((addr >> 0) & 0xff);
	spi_cs(0);
	flash_wait_completion();
}

void flash_write_enable()
{
	spi_cs(1);
	spi_write8(FLASH_WREN);
	spi_cs(0);
}

void flash_program_page(uint32_t addr, const uint8_t * data, int size)
{
	int i;
	spi_cs(1);
	spi_write8(FLASH_PP);	/* Page Program */
	spi_write8((addr >> 16) & 0x00ff);	/* Address to start writing (MSB) */
	spi_write8((addr >> 8) & 0x00ff);	/* Address to start writing */
	spi_write8(addr & 0x00ff);	/* Address to start writing (LSB) */
	for (i = 0; i < size; i++)
		spi_write8(data[i]);
	for (; i < FLASH_PAGE_SIZE; i++)
		spi_write8(0xff);
	spi_cs(0);
	flash_wait_completion();
}

void flash_program(uint32_t addr, const uint8_t * data, int size)
{
	int n = 0;
	int sector_map[FLASH_SIZE / FLASH_SECTOR_SIZE];
	memset(sector_map, 0, sizeof(sector_map));
	const uint8_t *p = data;

	while (n < size) {
		int plen = (size > FLASH_PAGE_SIZE ? FLASH_PAGE_SIZE : size);
		int sector = ((addr + n) / FLASH_SECTOR_SIZE);

		if (!sector_map[sector]) {
			flash_write_enable();
			fprintf(stderr, "Erasing sector 0x%x                \r",
				addr + n);
			flash_erase_sector(addr + n);
			sector_map[sector] = 1;
		}

		flash_write_enable();
		flash_program_page(addr + n, data + n, plen);

		fprintf(stderr, "Programming page %d/%d.             \r",
			n / FLASH_PAGE_SIZE,
			(size + FLASH_PAGE_SIZE - 1) / FLASH_PAGE_SIZE - 1);

		n += plen;
	}

	spi_cs(1);
	spi_write8(FLASH_READ);

	spi_write8((addr >> 16) & 0xff);
	spi_write8((addr >> 8) & 0xff);
	spi_write8((addr >> 0) & 0xff);
	fprintf(stderr, "\nVerification...\n");
	for (n = 0, p = data; n < size; p++, n++) {
		uint8_t d = spi_read8();
		if (d != *p) {
			fprintf(stderr,
				"Verification failed at offset 0x%06x (is: 0x%02x, should be: 0x%02x)\n.",
				addr + n, d, *p);
			spi_cs(0);
			exit(-1);
		}
	}
	spi_cs(0);


}

int program_flash(char *name, uint8_t *buf, size_t size, int program_boot)
{
	printf("Programming the Application FPGA flash with bitstream %s.\n",
	       name);

	if (!spi_test_presence())
	{
		fprintf(stderr,
			"SPI Master core not responding. You are probably be running an\nold version of the bootloader that doesn't support flash programming via VME.\n");
		return -1;
	}

	if (flash_read_id() != ID_M25P128) {
		fprintf(stderr,
			"Flash memory ID invalid. You are probably be running an old version\nof the bootloader that doesn't support flash programming via VME.\n");
		return -1;
	}

	if(program_boot)
	{
	    char confirm[1024];	    
	    printf("\nWARNING! You're about to update the SVEC bootloader. \nIf this operation fails (due to incorrect bitstream or power loss), the card "
		   "can be only recovered through JTAG.\n\n");

	    printf("Type 'yes' to continue or Ctrl-C to exit the program: ");
	    fgets(confirm, 1024, stdin);
	    if(strncmp(confirm,"yes", 3))
	    {
		    printf("Bootloader update aborted.\n");
		    return -1;
	    }
	    flash_program(0, buf, size);
	} else {
	    flash_program(BOOTLOADER_SDB_BASE, sdb_header, sizeof(sdb_header));
	    flash_program(BOOTLOADER_BITSTREAM_BASE, buf, size);
    	    printf("Programming OK.\n");

	}
	return 0;
}

int program_afpga(char *name, uint8_t *buf, size_t size)
{
	size_t i = 0;

	printf("Booting the Application FPGA with bitstream %s.\n",
	       name);

    csr_writel(SXLDR_CSR_SWRST, SXLDR_REG_CSR);
    csr_writel(SXLDR_CSR_START | SXLDR_CSR_MSBF, SXLDR_REG_CSR);

    while(i < size) {
		if(! (csr_readl(SXLDR_REG_FIFO_CSR) & SXLDR_FIFO_CSR_FULL)) 
		{
		
			uint32_t word = *(uint32_t *) ( buf + i );
		    size_t n = (size-i>4?4:size-i);
		    csr_writel((n - 1) | ((n<4) ? SXLDR_FIFO_R0_XLAST : 0), SXLDR_REG_FIFO_R0);
		    csr_writel(htonl(word), SXLDR_REG_FIFO_R1);
		    i+=n;
		}
    }
	
    while(1) 
    {
	uint32_t rval = csr_readl(SXLDR_REG_CSR);

	if(rval & SXLDR_CSR_DONE) {
	    printf("Bitstream loaded, status: %s\n", (rval & SXLDR_CSR_ERROR ? "ERROR" : "OK"));
/* give the VME bus control to App FPGA */
            csr_writel(SXLDR_CSR_EXIT, SXLDR_REG_CSR);
	    if ( rval & SXLDR_CSR_ERROR )
	    	return -1;
	    return 0;
	}
    }

    return 0;
}

int main(int argc, char *argv[])
{
	FILE *f;
	void *buf;
	uint32_t size;
	int slot;
	int program_boot = 0;
	int direct_boot = 0;
	int rv;

	if (argc < 3) {
		printf("usage: %s slot bitstream.bin [-b]\n", argv[0]);
		printf("   -b: updates the bootloader itself\n");
		printf("   -f: loads the bitstream straight to the Application FPGA (without programming the flash)\n");
		return 0;
	}
	
	if(argc > 3 && !strcmp(argv[3], "-b"))
	{
	    program_boot = 1;
	} else	if(argc > 3 && !strcmp(argv[3], "-f"))
	{
	    direct_boot = 1;
	} 


	f = fopen(argv[2], "rb");
	if (!f) {
		perror("fopen()");
		return -1;
	}
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	rewind(f);
	buf = malloc(size);
	fread(buf, 1, size, f);
	fclose(f);


	slot = atoi(argv[1]);

	init_vme(slot);
	enter_bootloader();

	if(!direct_boot)
	    rv = program_flash(argv[2], buf, size, program_boot);
	else
	    rv = program_afpga(argv[2], buf, size);



	free(buf);
	return rv;
}
