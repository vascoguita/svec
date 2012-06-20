#include <stdio.h>

#include "sveclib.h"

int main()
{
    void *card =svec_open(8);
    
    svec_writel(card,  0x1deadbee, 0x20400);

    printf("readback:%x\n",    svec_readl(card, 0x20400));

}