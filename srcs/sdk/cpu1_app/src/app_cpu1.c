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
    volatile int *local_counter = cpu1_local_ctr;
    int done = 0;

    /* Use a random number as the thread ID */
    srand((int) &local_counter);
    thread_id = rand();

    /* initialize the system */
    *local_counter = 0;

    /* Set the trigger signal to activate CPU0 */;
    *start_trigger = 1;

    while (! done)
    {
        lock_mutex(thread_id);

        /* Entering critical section */
        done = (*shared_counter >= COUNTER_LIMIT);
        if (! done)
        {
            (*shared_counter)++;
            (*local_counter)++;
        }
        /* Leaving critical section */

        unlock_mutex(thread_id);
    }

    return 0;
}
