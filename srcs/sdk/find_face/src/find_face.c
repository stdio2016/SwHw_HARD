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
// uncomment this to profile with real-time timer
//#define TIMER_PROFILING

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

#ifdef TIMER_PROFILING
long ticks_to_msec(uint64_t ticks)
{
	return (long) (ticks / (1000 * COUNTS_PER_USECOND));
}
#endif

/* function prototypes. */
void median3x3(uint8 *image, int width, int height);
int32 compute_sad(uint8 *im1, int w1, uint8 *im2, int w2, int h2, int row, int col);
int32 match(CImage *group, CImage *face, int *posx, int *posy);

/* SD card I/O variables */
static FATFS fatfs;

#ifdef TIMER_PROFILING
// Compute time
uint64_t sad_time, matrix_to_array_time, insertion_sort_time;
#endif

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
#ifdef TIMER_PROFILING
    printf("matrix_to_array takes %ldms\n", ticks_to_msec(matrix_to_array_time));
    printf("insertion_sort takes %ldms\n", ticks_to_msec(insertion_sort_time));
#endif

    /* Perform face-matching */
    printf("3. Face-matching ... ");
    tick = get_usec_time();
    cost = match(&group, &face, &posx, &posy);
    tick = get_usec_time() - tick;
    printf("done in %ld msec.\n\n", tick/1000);
    printf("** Found the face at (%d, %d) with cost %ld\n\n", posx, posy, cost);
#ifdef TIMER_PROFILING
    printf("compute_sad takes %ldms\n", ticks_to_msec(sad_time));
#endif

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
#ifdef TIMER_PROFILING
    uint64_t t1, t2, t3;
#endif

    for (row = 1; row < height-1; row++)
    {
        for (col = 1; col < width-1; col++)
        {
            ptr = image + row*width + col;
#ifdef TIMER_PROFILING
            XTime_GetTime(&t1);
#endif
            matrix_to_array(pix_array, ptr, width);
#ifdef TIMER_PROFILING
            XTime_GetTime(&t2);
#endif
            insertion_sort(pix_array, 9);
#ifdef TIMER_PROFILING
            XTime_GetTime(&t3);
#endif
            *ptr = pix_array[4];
#ifdef TIMER_PROFILING
            matrix_to_array_time += t2 - t1;
            insertion_sort_time += t3 - t2;
#endif
        }
    }
}

int32 compute_sad(uint8 *image1, int w1, uint8 *image2, int w2, int h2,
                  int row, int col)
{
    int  x, y;
    int32 sad = 0;

    /* Note: the following implementation is intentionally inefficient! */
    for (x = 0; x < w2; x++)
    {
        for (y = 0; y < h2; y++)
        {
            /* compute the sum of absolute difference */
            sad += abs(image2[y*w2+x] - image1[(row+y)*w1+(col+x)]);
        }
    }
    return sad;
}

int32 match(CImage *group, CImage *face, int *posx, int *posy)
{
    int  row, col;
    int32  sad, min_sad;

    min_sad = 256*face->width*face->height;
    for (row = 0; row < group->height-face->height; row++)
    {
        for (col = 0; col < group->width-face->width; col++)
        {
#ifdef TIMER_PROFILING
            uint64_t t1;
            XTime_GetTime(&t1);
#endif
            /* trying to compute the matching cost at (col, row) */
            sad = compute_sad(group->pix, group->width,
                              face->pix, face->width, face->height,
                              row, col);
#ifdef TIMER_PROFILING
            uint64_t t2;
            XTime_GetTime(&t2);
            sad_time += t2 - t1;
#endif

            /* if the matching cost is minimal, record it */
            if (sad <= min_sad)
            {
                min_sad = sad;
                *posx = col, *posy = row;
            }
        }
    }
    return min_sad;
}
