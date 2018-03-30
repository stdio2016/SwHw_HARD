/* //////////////////////////////////////////////////////////////////// */
/*	Program	: image.h                                                   */
/*	Author	: Chun-Jen Tsai                                             */
/*	Date	: Aug/13/2010                                               */
/*--------------------------------------------------------------------- */
/*	This is a image I/O library for Portable Any Map (PNM) images.      */
/* //////////////////////////////////////////////////////////////////// */

#ifndef __IMAGE_H__

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef signed char        int8;
typedef signed short       int16;
typedef signed long        int32;
typedef signed long long   int64;

typedef unsigned char      uint8;
typedef unsigned short     uint16;
typedef unsigned long      uint32;
typedef unsigned long long uint64;

typedef struct
{
    uint8 *pix;
    int32 width, height;
    int32 depth;
} CImage;

void *get_memory(char *name, int32 size);
int read_pnm_image(const char *filename, CImage *image);
int write_pnm_image(const char *filename, CImage *image);

#ifdef __cplusplus
}
#endif

#define __IMAGE_H__
#endif
