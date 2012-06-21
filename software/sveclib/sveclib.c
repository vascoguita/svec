#include <stdio.h>
#include <stdlib.h>

#include "libvmebus.h"

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/signal.h>
#include <arpa/inet.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>

#include "sveclib.h"
#include "xloader_regs.h"
#include "wb_uart.h"

#define BASE_LOADER 0x70000

struct svec_private {
    int slot;
    void *base;
    struct vme_mapping mapping;
    uint32_t vuart_base;
};

void *svec_open(int slot)
{
    struct svec_private *card = malloc(sizeof(struct svec_private));

    if(!card)
	return NULL;

    struct vme_mapping *mapping = &card->mapping;

    card->slot = slot;
	
    mapping->am                     =  0x9;  
    mapping->data_width             =  VME_D32;
    mapping->vme_addru              =  0;                                                                                                                                
    mapping->vme_addrl              =  (slot*2) * 0x80000;
    mapping->sizeu                  =  0;
    mapping->sizel                  =  0x80000;                                                                                                                           
    mapping->read_prefetch_enabled  =  0;                                                                                                                                
    mapping->bcast_select           =  0;                                                                                                                                
    mapping->window_num             =  0;

    card->base = vme_map(mapping, 0);
	
    if(!card->base)
    {
        fprintf(stderr, "mapping base I/O space failed\n");
 //		free(card);
 //		return NULL;
    }   
	
    return card;
}

void svec_close(void *card)
{
    struct svec_private *p = (struct svec_private *) card;
		if(!card)
			return;
		vme_unmap(&p->mapping, 0);
    free(card);
}

void svec_writel(void *card, uint32_t data, uint32_t addr)
{
    struct svec_private *p = (struct svec_private *) card;
    *(volatile uint32_t *) (p->base + addr) = swapbe32(data);
}

uint32_t svec_readl(void *card, uint32_t addr)
{
    struct svec_private *p = (struct svec_private *) card;
    uint32_t rv = swapbe32(*(volatile uint32_t *) (p->base + addr));
//    printf("readl: addr %x data %x\n", addr, rv);
    return rv;
}


static inline void csr_writel(void *csr, uint32_t data, uint32_t addr)
{
    *(volatile uint32_t *) (csr + addr) = swapbe32(data);
}

static inline uint32_t csr_readl(void *csr, uint32_t addr)
{
    uint32_t rv = swapbe32(*(volatile uint32_t *) (csr + addr));
    return rv;
}

static char *load_binary_file(const char *filename, size_t *size)
{
	int i;
	struct stat stbuf;
	char *buf;
	FILE *f;

	f = fopen(filename, "r");
	if (!f) 
		return NULL;

	if (fstat(fileno(f), &stbuf))
	{
		fclose(f);
		return NULL;
	}

	if (!S_ISREG(stbuf.st_mode))
	{
		fclose(f);
		return NULL;
	}

	buf = malloc(stbuf.st_size);
	if (!buf) 
	{
		fclose(f);
		return NULL;
    }
    
	i = fread(buf, 1, stbuf.st_size, f);
	if (i < 0) {
		fclose(f);
		free(buf);
		return NULL;
	}
	if (i != stbuf.st_size) {
		fclose(f);
		free(buf);
		return NULL;
	}

	fclose(f);
	*size = stbuf.st_size;
	return buf;
}


int svec_load_lm32(void *card, const char *filename, uint32_t base_addr)
{
	char *buf;
	uint32_t *ibuf;
	size_t size;
	int i;
	
	buf = load_binary_file(filename, &size);
	if(!buf)
		return -1;

	/* Phew... we are there, finally */
	svec_writel(card, 0x1deadbee, base_addr + 0x20400);

 while ( ! (svec_readl(card, base_addr + 0x20400) & (1<<28)) );

	ibuf = (uint32_t *) buf;
	for (i = 0; i < (size + 3) / 4; i++) 
	{
//	    fprintf(stderr, "i %x\n", i);
		svec_writel(card, htonl(ibuf[i]), base_addr + i*4);
	}
	sync();

	for (i = 0; i < (size + 3) / 4; i++) {
		uint32_t r = svec_readl(card, base_addr + i * 4);
		if (r != htonl(ibuf[i]))
		{
			fprintf(stderr, "programming error at %x "
				"(expected %08x, found %08x)\n", i*4,
				htonl(ibuf[i]), r);
			return -1;
		}
	}
	
	sync();

	svec_writel(card, 0x0deadbee, base_addr + 0x20400);
	return 0;
}


int svec_load_bitstream(void *card, const char *filename)
{
    struct svec_private *p = (struct svec_private *) card;
    int i = 0;
    const uint32_t boot_seq[8] = {0xde, 0xad, 0xbe, 0xef, 0xca, 0xfe, 0xba, 0xbe};
    const char svec_idr[4] = "SVEC";
    char idr[5];
    uint32_t *buf;
    size_t size;
    void *csr;
    struct vme_mapping mapping;


    buf = (uint32_t * )load_binary_file(filename, &size);
    if(!buf)
	return -1;

    mapping.am                     =  0x2f;   /* CS/CSR space */
    mapping.data_width             =  VME_D32;
    mapping.vme_addru              =  0;                                                                                                                                
    mapping.vme_addrl              =  p->slot * 0x80000;
    mapping.sizeu                  =  0;
    mapping.sizel                  =  0x80000;                                                                                                                           
    mapping.read_prefetch_enabled  =  0;                                                                                                                                
    mapping.bcast_select           =  0;                                                                                                                                
    mapping.window_num             =  0;

    csr = vme_map(&mapping, 0);

    if(!csr)
    {
	fprintf(stderr,"Mapping CSR space failed.\n");
	return -1;
	free(buf);
    }             
           
/* magic sequence: unlock bootloader mode, disable application FPGA */  
    for(i=0;i<8;i++)
	csr_writel(csr, boot_seq[i], BASE_LOADER + XLDR_REG_BTRIGR);

/* check if we are really talking to a SVEC */
    uint32_t idc = csr_readl(csr, BASE_LOADER + XLDR_REG_IDR);
    
    idr[0] = (idc >> 24) & 0xff;
    idr[1] = (idc >> 16) & 0xff;
    idr[2] = (idc >> 8) & 0xff;
    idr[3] = (idc >> 0) & 0xff;
    idr[4] = 0;
    
    printf("IDCode: '%s'\n", idr);

    if(strncmp(idr, svec_idr, 4))
    {
	fprintf(stderr,"Invalid IDCode value. \n");
	free(buf);
	return -1;
    }
	
    csr_writel(csr, XLDR_CSR_SWRST, BASE_LOADER + XLDR_REG_CSR);
    csr_writel(csr, XLDR_CSR_START | XLDR_CSR_MSBF, BASE_LOADER + XLDR_REG_CSR);

    while(i < size) {
	if(! (csr_readl(csr, BASE_LOADER + XLDR_REG_FIFO_CSR) & XLDR_FIFO_CSR_FULL)) {
	    int n = (size-i>4?4:size-i);
	    csr_writel(csr, (n - 1) | ((n<4) ? XLDR_FIFO_R0_XLAST : 0), BASE_LOADER + XLDR_REG_FIFO_R0);
	    csr_writel(csr, htonl(buf[i>>2]), BASE_LOADER + XLDR_REG_FIFO_R1);
	    i+=n;
	}
    }
	
    free(buf);

    while(1) 
    {
	uint32_t rval = csr_readl(csr, BASE_LOADER + XLDR_REG_CSR);
	if(rval & XLDR_CSR_DONE) {
    	    printf("Bitstream loaded, status: %s\n", (rval & XLDR_CSR_ERROR ? "ERROR" : "OK"));
/* give the VME bus control to App FPGA */
            csr_writel(csr, XLDR_CSR_EXIT, BASE_LOADER + XLDR_REG_CSR);
	    vme_unmap(&mapping, 0);
            return rval & XLDR_CSR_ERROR ? -1 : 0;
	}
    }
    
    return -1;
};

static int vuart_rx(void *card)
{
    struct svec_private *p = (struct svec_private *) card;
    int rdr = svec_readl(card, p->vuart_base + UART_REG_HOST_RDR);
    if(rdr & UART_HOST_RDR_RDY)
	return UART_HOST_RDR_DATA_R(rdr);
    else
	return -1;
}

static void vuart_tx(void *card, int c)
{
    struct svec_private *p = (struct svec_private *) card;
	while( svec_readl(card, p->vuart_base + UART_REG_SR) & UART_SR_RX_RDY);
	svec_writel(card, UART_HOST_TDR_DATA_W(c), p->vuart_base + UART_REG_HOST_TDR);
}

int svec_vuart_init(void *card, uint32_t base_addr)
{
	struct svec_private *p = (struct svec_private *) card;
	p->vuart_base = base_addr;
	return 0;
}

size_t svec_vuart_rx(void *card, char *buffer, size_t size)
{
	size_t s = size, n_rx = 0;
	while(s--)
	{
		int c =  vuart_rx(card);
		if(c < 0)
			return n_rx;
		*buffer++ = (char) c;
		n_rx ++;
	}
	return n_rx;
}

size_t svec_vuart_tx(void *card, char *buffer, size_t size)
{
	size_t s = size;
	while(s--)
		vuart_tx(card, *buffer++);
	
	return size;
}

