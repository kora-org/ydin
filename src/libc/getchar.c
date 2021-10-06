#include "fslc_stdio.h"

int fslc_getchar(void)
{
    return fslc_getc(fslc_stdin);
}
