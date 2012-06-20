#ifndef __SVECLIB_H
#define __SVECLIB_H

#include <stdint.h>


/* 'Opens' the SVEC card at VME slot [slot].
    Returns a handle to the card or NULL in case of failure. */
void *svec_open(int slot);

/* Closes the SVEC handle [card] */
void svec_close(void *card);

/* Loads the FPGA bitstream into card [card] from file [filename]. 
   Returns 0 on success. */
int svec_load_bitstream(void *card, const char *filename);

/* Loads the WRC LM32 firmware into card [card] from file [filename]. starting at 
   address [base_addr]. Returns 0 on success. 
   WARNING: using improper base address/FPGA firmware will freeze the computer. */
int svec_load_lm32(void *card, const char *filename, uint32_t base_addr);

/* Raw I/O to BAR4 (Wishbone) */
void svec_writel(void *card, uint32_t data, uint32_t addr);
uint32_t svec_readl(void *card, uint32_t addr);

/* Initializes a virtual UART at base address [base_addr]. */
int svec_vuart_init(void *card, uint32_t base_addr);

/* Virtual uart Rx (VUART->Host) and Tx (Host->VUART) functions */
size_t svec_vuart_rx(void *card, char *buffer, size_t size);
size_t svec_vuart_tx(void *card, char *buffer, size_t size);

int svec_flash_read(void *card, int flash_id, uint32_t offset, void *buffer, uint32_t size);
int svec_flash_write(void *card, int flash_id, uint32_t offset, void *buffer, uint32_t size);
int svec_flash_protect(void *card, int flash_id, uint32_t offset, uint32_t size, int on_off);

#endif
