/* ///////////////////////////////////////////////////////////////////// */
/*  File   : app_cpu0.c                                                  */
/*  Author : Chun-Jen Tsai                                               */
/*  Date   : 05/16/2017                                                  */
/* --------------------------------------------------------------------- */
/*  This program is used to test a hardware mutex by sharing a counter   */
/*  between two threads running on two Cortex A9's.                      */
/*                                                                       */
/*  This program is designed for the undergraduate course "Introduction  */
/*  to HW-SW Codesign and Implementation" at the department of Computer  */
/*  Science, National Chiao Tung University.                             */
/*  Hsinchu, 30010, Taiwan.                                              */
/* ///////////////////////////////////////////////////////////////////// */

#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xil_cache.h"

#define COUNTER_LIMIT 1000000

volatile int *hardware_mutex = (int *) (XPAR_MY_SYNC_0_S00_AXI_BASEADDR + 0);
volatile int *shared_counter = (int *) (XPAR_MY_SYNC_0_S00_AXI_BASEADDR + 4);
volatile int *start_trigger  = (int *) (XPAR_MY_SYNC_0_S00_AXI_BASEADDR + 8);
volatile int *cpu1_local_ctr = (int *) (XPAR_MY_SYNC_0_S00_AXI_BASEADDR + 12);
int cpu0_local_ctr;

void lock_mutex(int thread_id)
{
    do {
        *hardware_mutex = thread_id;
    } while (*hardware_mutex != thread_id)  /* busy waiting */;
}

void unlock_mutex(int thread_id)
{
    *hardware_mutex = thread_id; /* set mutex to 0 */
}

int main(int argc, char **argv)
{
    int thread_id;
    volatile int *local_counter = &cpu0_local_ctr;
    int done = 0;

    /* Use a random number as the thread ID */
    srand((int) &local_counter);
    thread_id = rand();

    /* initialize the system */
    *shared_counter = 0;
    *local_counter  = 0;
    *start_trigger  = 0;

    printf("\nCPU0 & CPU1 are about to tick the shared counter at [0x%08x].\n",
    		(unsigned int) shared_counter);
    printf("CPU0 waiting for CPU1 to start ...\n");
    while (*start_trigger == 0) /* busy waiting for trigger signal from CPU1 */;
    *start_trigger = 0;

    unsigned int disturbance = 0;
    while (! done)
    {
        lock_mutex(thread_id);

        /* Entering critical section */
        done = (*shared_counter >= COUNTER_LIMIT);
        if (! done)
        {
            (*shared_counter)++;
            (*local_counter)++;
            disturbance += *hardware_mutex;
        }
        /* Leaving critical section */
        unlock_mutex(thread_id);
    }

    printf("At the end, the shared counter = %d\n", *shared_counter);
    printf("Local CPU0 counter = %d\n", *local_counter);
    printf("Local CPU1 counter = %d\n", *cpu1_local_ctr);
    if (*shared_counter != (*local_counter + *cpu1_local_ctr))
        printf("CPU0 counter + CPU1 counter != Shared counter, the counter is corrupted.\n");
    else if (disturbance != thread_id * ((unsigned) *local_counter)) {
        puts("mutex is broken");
    }
    else if (*local_counter == 0 || *cpu1_local_ctr == 0)
        printf("Only one of the threads accesses the shared counter, not good.\n");
    else
    	printf("The shared counter is protected well.\n");
    return 0;
}
