#include "fslc_stdio.h"

int fslc_getc(FSLC_FILE *stream)
{
    if (stream->ungetc_buf >= 0)
    {
        int retval = stream->ungetc_buf;
        stream->ungetc_buf = -1;
        return retval;
    }
    return stream->getc(stream);
}
