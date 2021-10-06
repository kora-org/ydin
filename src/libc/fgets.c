#include "fslc_stdio.h"

char *fslc_fgets(char *str, int num, FSLC_FILE *stream)
{
    int i;
    --num;
    for (i = 0; i < num; ++i)
    {
        int c = fslc_getc(stream);
        if (c < 0)
        {
            str[i] = 0;
            break;
        }
        str[i] = c;
        
        if (c == '\n')
        {
            str[i+1] = 0;
            break;
        }
    }
    str[num] = 0;
    return str;
}
