// code from teacher Chun-Jen Tsai
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xparameters.h>
#include "xil_cache.h"
#define goodTest  "01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890ABC"

volatile int *hw_active = (int *) (XPAR_MY_DMA_0_S00_AXI_BASEADDR +  0);
volatile int *dst_addr  = (int *) (XPAR_MY_DMA_0_S00_AXI_BASEADDR +  4);
volatile int *src_addr  = (int *) (XPAR_MY_DMA_0_S00_AXI_BASEADDR +  8);
volatile int *copy_len  = (int *) (XPAR_MY_DMA_0_S00_AXI_BASEADDR +  12);

char test_text[1024] = "This is a 64-byte string used to test the burst copy operation."
		"\n123456789012345678901234567890";
int test_arr1[128], test_arr2[128];

/* ========================================================================== */
/*  Note: This HW IP always copies 16 words of data from *src to *dst.        */
/* ========================================================================== */
void hw_memcpy_16w(void *dst, void *src, int size)
{
    *dst_addr = (int) dst;   // destination word address
    *src_addr = (int) src;   // source word address
    *copy_len = size;

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
    strcpy(dst, goodTest goodTest);

    printf("\n");
    printf("(1) The source data @ addr [%08X] are:\n\n    \"%s\"\n\n",
    		(unsigned int) src, src);
    printf("(2) The destination data @ addr [%08X] are:\n\n    \"%s\"\n\n",
    		(unsigned int) dst, dst);
    printf("(3) Copying 16 words of data from [%08X] to [%08X] ...\n\n",
    		(unsigned int) src, (unsigned int) dst);
    hw_memcpy_16w((void *) dst, (void *) src, 72);
    printf("(4) The new data at the destination is:\n\n    \"%s\"\n", dst);
    free(dst);
    int i;
    for (i=0;i<128;i++){
    	test_arr1[i] = i * 10;
    }
    hw_memcpy_16w((void *)test_arr2, (void *)test_arr1, 512);
    for (i=100;i<128;i++){
    	printf("%d\n", test_arr2[i]);
    }
    return 0;
}
