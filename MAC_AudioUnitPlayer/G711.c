//
//  G711.c
//  G711
//
//  Created by Ruiwen Feng on 2017/6/1.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#include "G711.h"

#define	QUANT_MASK	(0xf)		/* Quantization field mask. */
#define	SEG_SHIFT	(4)		/* Left shift for segment number. */
#define	SEG_MASK	(0x70)		/* Segment field mask. */
#define	SIGN_BIT	(0x80)		/* Sign bit for a A-law byte. */


static short seg_aend[8] = {0x1F, 0x3F, 0x7F, 0xFF,
    0x1FF, 0x3FF, 0x7FF, 0xFFF};

static int search(int val, short	*table, int	size)
{
    short i;
    
    for (i = 0; i < size; i++) {
        if (val <= *table++)
            return (i);
    }
    return (size);
}

unsigned char linear2alaw(short pcm_val)	/* 2's complement (16-bit range) */
{
    short	 mask;
    short	 seg;
    unsigned char aval;
    
    pcm_val = pcm_val >> 3;
    
    if (pcm_val >= 0) {
        mask = 0xD5;		/* sign (7th) bit = 1 */
    } else {
        mask = 0x55;		/* sign bit = 0 */
        pcm_val = -pcm_val - 1;
    }
    
    /* Convert the scaled magnitude to segment number. */
    seg = search(pcm_val, seg_aend, 8);
    
    /* Combine the sign, segment, and quantization bits. */
    
    if (seg >= 8)		/* out of range, return maximum value. */
        return (unsigned char) (0x7F ^ mask);
    else {
        aval = (unsigned char) seg << SEG_SHIFT;
        if (seg < 2)
            aval |= (pcm_val >> 1) & QUANT_MASK;
        else
            aval |= (pcm_val >> seg) & QUANT_MASK;
        return (aval ^ mask);
    }
}

short alaw2linear(
            unsigned char	a_val)
{
    short t;
    short seg;
    
    a_val ^= 0x55;
    
    t = (a_val & QUANT_MASK) << 4;
    seg = ((unsigned)a_val & SEG_MASK) >> SEG_SHIFT;
    switch (seg) {
        case 0:
            t += 8;
            break;
        case 1:
            t += 0x108;
            break;
        default:
            t += 0x108;
            t <<= seg - 1;
    }
    return ((a_val & SIGN_BIT) ? t : -t);
}


int g711a_decode( short amp[], const unsigned char g711a_data[], int g711a_bytes )
{
    int i;
    int samples;
    unsigned char code;
    int sl;
    
    for ( samples = i = 0; ; )
    {
        if (i >= g711a_bytes)
            break;
        code = g711a_data[i++];
        
        sl = alaw2linear( code );
        
        amp[samples++] = (short) sl;
    }
    return samples*2;
}


int g711a_encode(unsigned char g711_data[], const short amp[], int len)
{
    int i;
    
    for (i = 0;  i < len;  i++)
    {
        g711_data[i] = linear2alaw(amp[i]);
    }
    
    return len;
}


