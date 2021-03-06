// modified by Yi-Feng Chen on 2018/06/29
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
#include <arm_neon.h>

#include "xparameters.h"  /* SDK generated parameters */
#include "xsdps.h"        /* for SD device driver     */
#include "ff.h"
#include "xil_cache.h"
#include "xplatform_info.h"
#include "xtime_l.h"
// uncomment this to profile with real-time timer
//#define TIMER_PROFILING
#define FastSAD_Addr  XPAR_FASTSAD_0_S00_AXI_BASEADDR

// set photo file name here
const char *groupname = "group.pgm";

// set face file name here
#define FACE_COUNT 4
const char *facename[FACE_COUNT] = {
    "face1.pgm",
    "face2.pgm",
    "face3.pgm",
    "face4.pgm"
};

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

// faster way of finding match
int32 compute_sad_neon(uint8 *im1, int w1, uint8 *im2, int w2, int h2, int row, int col, int32 current_min);
int32 fastsad(uint8 *image1, int w1, uint8 *image2, int row, int col);
int32 fastsad_hw(CImage *group, CImage *face, int *posx, int *posy);

/* SD card I/O variables */
static FATFS fatfs;

#ifdef TIMER_PROFILING
// Compute time
uint64_t sad_time, matrix_to_array_time, insertion_sort_time;
#endif

int main(int argc, char **argv)
{
    CImage group, face[FACE_COUNT];
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
    if (read_pnm_image(groupname, &group))
    {
        printf("\nError: cannot read the group.pgm image.\n");
    	return 1;
    }
    width = group.width, height = group.height;

    for (int i = 0; i < 4; i++) {
        /* Reading the 32x32 target face image into main memory */
        if (read_pnm_image(facename[i], &face[i]))
        {
            printf("\nError: cannot read the face.pgm image.\n");
            return 1;
        }
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
    printf("3. Face-matching ... \n");
    for (int i = 0; i < FACE_COUNT; i++) {
        printf("\t(%d) Match \"%s\": ", i, facename[i]);
        tick = get_usec_time();
        //cost = match(&group, &face[i], &posx, &posy);
        cost = fastsad_hw(&group, &face[i], &posx, &posy);
        tick = get_usec_time() - tick;
        printf("done in %ld msec.\n", tick/1000);
        printf("** Found the face at (%d, %d) with cost %ld\n", posx, posy, cost);
#ifdef TIMER_PROFILING
        printf("compute_sad takes %ldms\n", ticks_to_msec(sad_time));
#endif

        /* free allocated memory */
        free(face[i].pix);
    }
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

int32 compute_sad_neon(uint8 *image1, int w1, uint8 *image2, int w2, int h2,
                  int row, int col, int32 current_min)
{
    int  x, y;
    //const uint8 const *img = image1 + row*w1 + col;
    int32 sad = 0;

    /* The program now runs 200% faster */
    for (y = 0; y < h2; y++)
    {
        for (x = 0; x < w2; x++)
        {
            /* compute the sum of absolute difference */
            //sad += abs(image2[y*w2+x] - img[y*w1+x]);
               sad += abs(image2[y*w2+x] - image1[(row+y)*w1+(col+x)]);
        }
        if (sad > current_min) return INT32_MAX;
    }
    return sad;
}

int32 fastsad(uint8 *image1, int w1, uint8 *image2, int row, int col)
{
#ifdef __ARM_NEON
    uint8x16_t f1,f2, g1,g2, dif1,dif2;
    uint16x8_t acc1, acc2;
    image1 += row*w1 + col;
    acc1 = vdupq_n_u16(0);
    acc2 = vdupq_n_u16(0);
    g1 = vld1q_u8(image1);
    f1 = vld1q_u8(image2);
    g2 = vld1q_u8(image1 + 16);
    f2 = vld1q_u8(image2 + 16);
    int i;
    for (i = 1; i < 32; i++) {
        image1 += w1;
        image2 += 32;
        dif1 = vabdq_u8(f1, g1);
        dif2 = vabdq_u8(f2, g2);
        g1 = vld1q_u8(image1);
        f1 = vld1q_u8(image2);
        g2 = vld1q_u8(image1 + 16);
        f2 = vld1q_u8(image2 + 16);
        acc1 = vpadalq_u8(acc1, dif1);
        acc2 = vpadalq_u8(acc2, dif2);
    }
    dif1 = vabdq_u8(f1, g1);
    dif2 = vabdq_u8(f2, g2);
    acc1 = vpadalq_u8(acc1, dif1);
    acc2 = vpadalq_u8(acc2, dif2);
    uint16x8_t some1 = vaddq_u16(acc1, acc2);
    uint32x4_t some2 = vpaddlq_u16(some1);
    uint32_t sads[4];
    vst1q_u32(sads, some2);
    return sads[0] + sads[1] + sads[2] + sads[3];
#else
    return compute_sad(image1, w1, image2, 32, 32, row, col);
#endif
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
            //sad = compute_sad_neon(group->pix, group->width,
            //                  face->pix, face->width, face->height,
            //                  row, col, min_sad);
            sad = fastsad(group->pix, group->width, face->pix, row, col);
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

// hardware interface
volatile int *hw_active = (int *) FastSAD_Addr;
volatile int *to_write = (int *) (FastSAD_Addr+4);
volatile int *len_copy = (int *) (FastSAD_Addr+8);
uint8_t * volatile *src_addr = (uint8_t **) (FastSAD_Addr+12);
// currently unused
//uint8_t * volatile *dst_addr = (uint8_t **) (FastSAD_Addr+16);
volatile int *dst_row = (int *) (FastSAD_Addr+20);
volatile int *face_select = (int *) (FastSAD_Addr+24);
// slv_reg7 is reserved
volatile int *min_sad = (int *) (FastSAD_Addr+32);
volatile int *min_sad_pos = (int *) (FastSAD_Addr+36);

// accelerate!
int32 fastsad_hw(CImage *group, CImage *face, int *posx, int *posy) {
    // store face
    *to_write = 1; // means "write face"
    *len_copy = 1024;
    *src_addr = face->pix;
    *dst_row = 0;
    *face_select = 0;
    *hw_active = 1;
    while (*hw_active != 0) ;

    // actually compute minimum SAD
    int minimum = INT32_MAX;
    for (int i = 0; i < group->height; i++) {
        *to_write = 3; // means "read a row and calculate SAD"
        *len_copy = group->width;
        *src_addr = group->pix + (group->width * i);
        *dst_row = i;
        *face_select = 0;
        for (*hw_active = 1; *hw_active != 0; ) ;
        if (i >= 31) {
            int current = *min_sad;
            if (current <= minimum) {
                minimum = current;
                *posx = *min_sad_pos - 31;
                *posy = i - 31;
            }
        }
    }
    return minimum;
}
