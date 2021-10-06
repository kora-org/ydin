#include "fslc_stdio.h"


static size_t _fslc_fread_impl(void *ptr, size_t count, FSLC_FILE *stream);

size_t fslc_fread(void *ptr, size_t size, size_t count, FSLC_FILE *stream)
{
    size_t res = _fslc_fread_impl(ptr, count * size, stream);

    return size > 0 ? res / size : 0;
}


static size_t _fslc_fread_impl(void *ptr, size_t count, FSLC_FILE *stream)
{
    size_t i;

    unsigned char *data = (unsigned char *)ptr;

    for (i=0; i < count; ++i, ++data)
    {
        int r = fslc_getc(stream);
        if (r < 0)
        {
            return i;
        }
        *data = r;
    }
    return count;
}
