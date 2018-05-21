// code from teacher Chun-Jen Tsai
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xparameters.h>
#include "xil_cache.h"

volatile int *hw_active = (int *) (XPAR_MY_DMA_0_S00_AXI_BASEADDR +  0);
volatile int *dst_addr  = (int *) (XPAR_MY_DMA_0_S00_AXI_BASEADDR +  4);
volatile int *src_addr  = (int *) (XPAR_MY_DMA_0_S00_AXI_BASEADDR +  8);

char test_text[] = "This is a 64-byte string used to test the burst copy operation.";

/* ========================================================================== */
/*  Note: This HW IP always copies 16 words of data from *src to *dst.        */
/* ========================================================================== */
void hw_memcpy_16w(void *dst, void *src)
{
    *dst_addr = (int) dst;   // destination word address
    *src_addr = (int) src;   // source word address

    *hw_active = 1;         // trigger the HW IP
    while (*hw_active);     // wait for the transfer to finish
}

int main(int argc, char **argv)
{
    char *src, *dst;

    /* Disable CPU cache for coherent data sharing between HW & SW */
    Xil_DCacheDisable();

	src = test_text;
    dst = (char *) malloc(sizeof(test_text));
    strcpy(dst, "01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890ABC");

    printf("\n");
    printf("(1) The source data @ addr [%08X] are:\n\n    \"%s\"\n\n",
    		(unsigned int) src, src);
    printf("(2) The destination data @ addr [%08X] are:\n\n    \"%s\"\n\n",
    		(unsigned int) dst, dst);
    printf("(3) Copying 16 words of data from [%08X] to [%08X] ...\n\n",
    		(unsigned int) src, (unsigned int) dst);
    hw_memcpy_16w((void *) dst, (void *) src);
    printf("(4) The new data at the destination is:\n\n    \"%s\"\n", dst);
    free(dst);
    return 0;
}
