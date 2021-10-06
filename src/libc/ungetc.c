#include "fslc_stdio.h"

int fslc_ungetc(int c, FSLC_FILE *stream)
{
    if (stream->ungetc_buf >= 0)
    {
        return -1;
    }
    stream->ungetc_buf = (unsigned char)c;
    return stream->ungetc_buf;
}
