/* //////////////////////////////////////////////////////////////////// */
/*	Program	: image.c                                                   */
/*	Author	: Chun-Jen Tsai                                             */
/*	Date	: Aug/13/2010, Feb/17/2017                                  */
/*--------------------------------------------------------------------- */
/*	This is a image I/O library for Portable Any Map (PNM) images.      */
/* //////////////////////////////////////////////////////////////////// */

#include "xparameters.h"  /* SDK generated parameters */
#include "xsdps.h"        /* for SD device driver     */
#include "ff.h"
#include "image.h"

void *get_memory(char *name, int32 size)
{
    void *p;

    if ((p = malloc(size)) == NULL)
    {
        printf("get_memory: No memory for '%s'!\n", name);
        exit(1);
    }
    return p;
}

int read_pnm_image(const char *filename, CImage *image)
{
	static FIL fobj;
    char buf[32];
    uint8 *ptr;
    unsigned int nbytes;
    int n, idx, max_level = 256, image_line;

	if (f_open(&fobj, filename, FA_READ))
	{
        printf("read_pnm_image: cannot open '%s'.\n", filename);
		return 1;
	}

    /* read PGM headers */
	if (f_read(&fobj, (void *) buf, 2, &nbytes))
	{
		return 1;
	}
    buf[2] = '\0';
    if (!strncmp(buf, "P5", 2))
    {
        image->depth = 8;
    }
    else if (!strncmp(buf, "P6", 2))
    {
        image->depth = 24;
    }
    else
    {
        printf("read_pnm_image: unsupported image file.\n");
        return 1;
    }

    /* read width, height, and max level */
    for (idx = 0; idx < 4; idx++)
    {
        n = 0;
        do
        {
        	f_read(&fobj, (void *) buf+n, 1, &nbytes);
        	if (nbytes == 1)
        	{
                if (buf[n] == 0x0a || buf[n] == ' ' ||
                    buf[n] == 0x0d || buf[n] == 0x09)
                {
                    buf[n] = '\0';
                    switch (idx)
                    {
                    case 0: /* skip trailing white space to "P5" */
                        break;
                    case 1: /* save width */
                        image->width = atoi(buf);
                        break;
                    case 2: /* save height */
                        image->height = atoi(buf);
                        break;
                    case 3: /* save max level */
                        max_level = atoi(buf);
                        break;
                    }
                    n = 0;
                    break;
                }
                else
                {
                    n++;
                }
            }
        } while (nbytes == 1);
    }

    if (max_level > 255)
    {
        printf("read_pnm_image: incorrect image format parameter(s).\n");
        return 1;
    }

    /* read the image data */
    image_line = image->width*image->depth/8;
    image->pix = ptr = get_memory("image->pix", image->height*image_line);
    for (idx = 0; idx < image->height; idx++)
    {
        f_read(&fobj, (void *) ptr, image_line, &nbytes);
        if (nbytes != image_line)
        {
            printf("read_pnm_image: image read error.\n");
            return 1;
        }
        ptr += image_line;
    }
    f_close(&fobj);
    return 0;
}

int write_pnm_image(const char *filename, CImage *image)
{
	static FIL fobj;
    char buf[32];
    int idx;
    uint8 *ptr;
    unsigned int nbytes;
    size_t image_line;

    if (image->depth != 8 && image->depth != 24)
    {
        printf("write_pnm_image: unsupported image depth.\n");
        return 1;
    }

	if (f_open(&fobj, filename, FA_CREATE_ALWAYS | FA_WRITE))
	{
        printf("write_pnm_image: cannot open '%s'.\n", filename);
		return 1;
	}

    /* write PGM headers */
    strncpy(buf, (image->depth == 8)? "P5\n" : "P6\n", sizeof(buf));
	f_write(&fobj, (void *) buf, strlen(buf), &nbytes);
    if (nbytes != strlen(buf))
    {
        printf("write_pnm_image: Error writing PGM signature.\n");
        return 1;
    }

    /* write width, height, and max level */
    snprintf(buf, sizeof(buf), "%ld %ld\n255\n", image->width, image->height);
	f_write(&fobj, (void *) buf, strlen(buf), &nbytes);
    if (nbytes != strlen(buf))
    {
        printf("write_pnm_image: Error writing PGM header.\n");
        return 1;
    }

    /* write the image */
    image_line = image->width*image->depth/8;
    ptr = image->pix;
    for (idx = 0; idx < image->height; idx++)
    {
    	f_write(&fobj, (void *) ptr, image_line, &nbytes);
        if (nbytes != image_line)
        {
            printf("write_pnm_image: image write error.\n");
            return 1;
        }
        ptr += image_line;
    }
    f_close(&fobj);
    return 0;
}
