/*
 * main.c
 *
 *  Created on: 2018/6/12
 *      Author: User
 */
#include "xtime_l.h"
#include "xparameters.h"
#include <stdio.h>
#include <stdlib.h>
#include "xil_cache.h"
#include <string.h>

#define TicksPerUsec  (XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ / 2000000)
#define FastSAD_Addr  XPAR_FASTSAD_0_S00_AXI_BASEADDR

long getRunTime() {
	XTime t;
	XTime_GetTime(&t);
	return (long)(t / TicksPerUsec);
}

long timeRead1 = 0, timeRead2 = 0, timeWrite = 0;

void testSpeed(uint8_t *src, uint8_t *src2, uint8_t *dst, int len) {
	volatile int *hw_active = (int *) FastSAD_Addr;
	volatile int *to_write = (int *) (FastSAD_Addr+4);
	volatile int *len_copy = (int *) (FastSAD_Addr+8);
	uint8_t * volatile *src_addr = (uint8_t **) (FastSAD_Addr+12);
	uint8_t * volatile *dst_addr = (uint8_t **) (FastSAD_Addr+16);
	volatile int *dst_row = (int *) (FastSAD_Addr+20);

	long t1 = getRunTime();
	*to_write = 0;
	*len_copy = len;
	*src_addr = src;
	*dst_row = 0;
	*hw_active = 1;
	while (*hw_active == 1) ;

	long t2 = getRunTime();
	*dst_row = 1;
	*src_addr = src2;
	*hw_active = 1;
	while (*hw_active == 1) ;

	long t3 = getRunTime();
	*to_write = 1;
	*dst_addr = dst;
	*hw_active = 1;
	while (*hw_active == 1) ;

	long t4 = getRunTime();
	timeRead1 += t2 - t1;
	timeRead2 += t3 - t2;
	timeWrite += t4 - t3;
}

uint8_t pic[1080][1920];
uint8_t pic2[1080][1920];
uint8_t zero[1920] = {0};

int obsolete_main(){
	printf("Hello world %p\n", pic[0]);
	long t0 = getRunTime();
	for (int i = 0; i < 1080; i++) {
		for (int j = 0; j < 1920; j++) {
			pic[i][j] = i*j;
		}
	}
	//Xil_DCacheFlush();
	long t1 = getRunTime();
    //Xil_DCacheDisable();
	for (int i = 0; i < 1080; i++) {
		testSpeed(pic[i], pic[i], pic[i], 1920);
	}
	long t2 = getRunTime();
	//Xil_DCacheEnable();
	printf("initialize: %ldus\n", t1 - t0);
	printf("HW copy test: %ldus\n", t2 - t1);
	for (int i = 0; i < 1080; i++) {
		for (int j = 0; j < 1920; j++) {
			uint8_t expect = i * j * 2;
			if (pic[i][j] != expect) {
				printf("%d %d %p %d\n", i, j, &pic[i][j], pic[i][j]);
			}
		}
	}
	printf("Hello 2\n");
	printf("%ld %ld %ld\n", timeRead1, timeRead2, timeWrite);
	exit(0);
}
