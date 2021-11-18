#include <stdlib.h>
#include <limits.h>

char *itoa(int value, char *buffer, int base) {
    char *pbuffer = buffer;
    int i = 0, len;
    int negative = 0;

    if (value == 0) {
        buffer[i++] = '0';
        buffer[i] = '\0';
        return buffer;
    }

    if (value < 0 && base == 10) {
        negative = 1;
        value = -value;
    }

    while (value > 0) {
        int digit = value % base;
        *(pbuffer++) = (digit < 10 ? '0' + digit : 'a' + digit - 10);
        value /= base;
    }

    if (negative)
        *(pbuffer++) = '-';

    *(pbuffer) = '\0';

    len = (pbuffer - buffer);
    for (i = 0; i < len / 2; i++) {
        char j = buffer[i];
        buffer[i] = buffer[len - i - 1];
        buffer[len - i - 1] = j;
    }

    return buffer;
}

int atoi(const char* str) {
    int sign = 1, base = 0, i = 0;
     
    while (str[i] == ' ') i++;
     
    if (str[i] == '-' || str[i] == '+') {
        sign = 1 - 2 * (str[i++] == '-');
    }
   
    while (str[i] >= '0' && str[i] <= '9') {
        if (base > INT_MAX / 10 || (base == INT_MAX / 10 && str[i] - '0' > 7)) {
            if (sign == 1)
                return INT_MAX;
            else
                return INT_MIN;
        }
        base = 10 * base + (str[i++] - '0');
    }

    return base * sign;
}
