// Modified by Yi-Feng Chen on 2018/04/11
/* ///////////////////////////////////////////////////////////////////// */
/*  File   : find_face.c                                                 */
/*  Author : Chun-Jen Tsai                                               */
/*  Date   : 02/09/2013                                                  */
/* --------------------------------------------------------------------- */
/*  This program will locate the position of a 32x32 face template       */
/*  in a group photo.                                                    */
/*                                                                       */
/*  This program is designed for the undergraduate course                */
/*  "Introduction to HW-SW Codesign and Implementation" at               */
/*  the department of Computer Science, National Chiao Tung University.  */
/*  Hsinchu, 30010, Taiwan.                                              */
/* ///////////////////////////////////////////////////////////////////// */

/* FreeRTOS includes. */
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "timers.h"
/* Xilinx includes. */
#include "xil_printf.h"
#include "xparameters.h"

#define TIMER_ID	1
#define DELAY_10_SECONDS	10000UL
#define DELAY_1_SECOND		1000UL
#define TIMER_CHECK_THRESHOLD	9
/*-----------------------------------------------------------*/

/* The Tx and Rx tasks as described at the top of this file. */
static void prvTxTask( void *pvParameters );
static void prvRxTask( void *pvParameters );
static void vTimerCallback( TimerHandle_t pxTimer );
/*-----------------------------------------------------------*/

/* The queue used by the Tx and Rx tasks, as described at the top of this
file. */
static TaskHandle_t xTxTask;
static TaskHandle_t xRxTask;
static QueueHandle_t xQueue = NULL;
static TimerHandle_t xTimer = NULL;
char HWstring[15] = "Hello World";
long RxtaskCntr = 0;

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include "image.h"

#include "xparameters.h"  /* SDK generated parameters */
#include "xsdps.h"        /* for SD device driver     */
#include "ff.h"
#include "xil_cache.h"
#include "xplatform_info.h"
#include "xtime_l.h"

/* Global Timer is always clocked at half of the CPU frequency */
#define COUNTS_PER_USECOND  (XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ / 2000000)
#define FREQ_MHZ ((XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ+500000)/1000000)

/* Declare a microsecond-resolution timer function */
long get_usec_time()
{
	XTime time_tick;

	XTime_GetTime(&time_tick);
	return (long) (time_tick / COUNTS_PER_USECOND);
}

/* function prototypes. */
void median3x3(uint8 *image, int width, int height);
int32 compute_sad(uint8 *im1, int w1, uint8 *im2, int w2, int h2, int row, int col);
int32 match(CImage *group, CImage *face, int *posx, int *posy);

int32 compute_sad_hw(uint8 *im1, int w1, uint8 *im2, int w2, int h2, int row, int col);

/* SD card I/O variables */
static FATFS fatfs;

int main(int argc, char **argv)
{
    CImage group, face;
    int  width, height;
    int  posx, posy;
    int32 cost;
    long tick;

    /* Initialize the SD card driver. */
	if (f_mount(&fatfs, "0:/", 0))
	{
		return XST_FAILURE;
	}

    printf("1. Reading images ... ");
    tick = get_usec_time();

    /* Read the group image file into the DDR main memory */
    if (read_pnm_image("group.pgm", &group))
    {
        printf("\nError: cannot read the group.pgm image.\n");
    	return 1;
    }
    width = group.width, height = group.height;

    /* Reading the 32x32 target face image into main memory */
    if (read_pnm_image("face.pgm", &face))
    {
        printf("\nError: cannot read the face.pgm image.\n");
    	return 1;
    }
    tick = get_usec_time() - tick;
    printf("done in %ld msec.\n", tick/1000);

    /* Perform median filter for noise removal */
    printf("2. Median filtering ... ");
    tick = get_usec_time();
    median3x3(group.pix, width, height);
    tick = get_usec_time() - tick;
    printf("done in %ld msec.\n", tick/1000);

    /* Perform face-matching */
    printf("3. Face-matching ... ");
    tick = get_usec_time();
    cost = match(&group, &face, &posx, &posy);
    tick = get_usec_time() - tick;
    printf("done in %ld msec.\n\n", tick/1000);
    printf("** Found the face at (%d, %d) with cost %ld\n\n", posx, posy, cost);

    /* free allocated memory */
    free(face.pix);
    free(group.pix);

    return 0;
}

void matrix_to_array(uint8 *pix_array, uint8 *ptr, int width)
{
    int  idx, x, y;

    idx = 0;
    for (y = -1; y <= 1; y++)
    {
        for (x = -1; x <= 1; x++)
        {
            pix_array[idx++] = *(ptr+x+width*y);
        }
    }
}

void insertion_sort(uint8 *pix_array, int size)
{
    int idx, jdx;
    uint8 temp;

    for (idx = 1; idx < size; idx++)
    {
        for (jdx = idx; jdx > 0; jdx--)
        {
            if (pix_array[jdx] < pix_array[jdx-1])
            {
                /* swap */
                temp = pix_array[jdx];
                pix_array[jdx] = pix_array[jdx-1];
                pix_array[jdx-1] = temp;
            }
        }
    }
}

void median3x3(uint8 *image, int width, int height)
{
    int   row, col;
    uint8 pix_array[9], *ptr;

    for (row = 1; row < height-1; row++)
    {
        for (col = 1; col < width-1; col++)
        {
            ptr = image + row*width + col;
            matrix_to_array(pix_array, ptr, width);
            insertion_sort(pix_array, 9);
            *ptr = pix_array[4];
        }
    }
}

#define SAD_ADDR XPAR_COMPUTE_SAD_0_S00_AXI_BASEADDR

int32 compute_sad(uint8 *image1, int w1, uint8 *image2, int w2, int h2,
                  int row, int col)
{
    int  x, y;
    int32 sad = 0;

    /* Note: the following implementation is intentionally inefficient! */
    for (y = 0; y < h2; y++)
    {
        for (x = 0; x < w2; x++)
        {
            /* compute the sum of absolute difference */
            sad += abs(image2[y*w2+x] - image1[(row+y)*w1+(col+x)]);
        }
    }
    return sad;
}

volatile char *R0_R7 = (char *) (SAD_ADDR);
volatile int *reg_bank = (int *) (SAD_ADDR + 32);
volatile int *hw_active = (int *) (SAD_ADDR + 36);
volatile int *result = (int *) (SAD_ADDR + 40);

int32 compute_sad_hw(uint8 *image1, int w1, uint8 *image2, int w2, int h2,
                  int row, int col)
{
    int y;
    int32 sad = 0;

    if (row == 0) {
        for (y = 0; y < h2; y++)
        {
            *reg_bank = y;
            memmove(R0_R7, image1+y*w1+col, 32);
        }
    }
    *reg_bank = row & 15;
    memmove(R0_R7, image1+row*w1+col, 32);
    *hw_active = 1;
	while (*hw_active == 1) ; // busy wait
    sad = *result;
    return sad;
}

int32 match(CImage *group, CImage *face, int *posx, int *posy)
{
    int  row, col;
    int32  sad, min_sad;

    min_sad = 256*face->width*face->height;
    for (row = 0; row < face->height; row++) {
        *reg_bank = row + 32;
        memmove(R0_R7, face->pix + row * face->width, face->width);
    }

    for (col = 0; col < group->width-face->width; col++)
    {
        for (row = 0; row < group->height-face->height; row++)
        {
            /* trying to compute the matching cost at (col, row) */
            sad = compute_sad_hw(group->pix, group->width,
                              face->pix, face->width, face->height,
                              row, col);

            /* if the matching cost is minimal, record it */
            if (sad <= min_sad)
            {
                min_sad = sad;
                *posx = col, *posy = row;
            }
            break;
        }
        break;
    }
    return min_sad;
}

