#include "fslc_stdio.h"

static size_t _fslc_fwrite_impl(const void *ptr, size_t count, FSLC_FILE *stream);

size_t fslc_fwrite(const void *ptr, size_t size, size_t count, FSLC_FILE *stream)
{
    if (stream->pre_output) stream->pre_output(stream);
    
    size_t res = _fslc_fwrite_impl(ptr, count * size, stream);
    
    if (stream->post_output) stream->post_output(stream);

    return size > 0 ? res / size : 0;
}


static size_t _fslc_fwrite_impl(const void *ptr, size_t count, FSLC_FILE *stream)
{
    size_t i;
    
    unsigned char *data = (unsigned char *)ptr;
    
    for (i=0; i < count; ++i, ++data)
    {
        int r = stream->putc(*data, stream);
        if (r < 0)
        {
            return i;   
        }
    }
    return count;
}
