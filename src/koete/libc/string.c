#include "string.h"
#include <limits.h>

int memcmp(const void *s1, const void *s2, size_t size) {
    const uint8_t *p1 = (const uint8_t *)s1;
    const uint8_t *p2 = (const uint8_t *)s2;

    for (size_t i = 0; i < size; i++) {
        if (p1[i] != p2[i])
            return p1[i] < p2[i] ? -1 : 1;
    }

    return 0;
}

void *memcpy(void *dest, const void *src, size_t size) {
#ifdef __x86_64__
    // use optimized memcpy in x86-64
    asm volatile("rep movsb"
                 : "=D"(dest),
                   "=S"(src),
                   "=c"(size)
                 : "D"(dest),
                   "S"(src),
                   "c"(size)
                 : "memory");
#else
    uint8_t *pdest = (uint8_t *)dest;
    const uint8_t *psrc = (const uint8_t *)src;

    for (size_t i = 0; i < size; i++)
        pdest[i] = psrc[i];
#endif
    return dest;
}

void *memmove(void *dest, const void *src, size_t size) {
    uint8_t *pdest = (uint8_t *)dest;
    const uint8_t *psrc = (const uint8_t *)src;

    if (dest < src) {
        for (size_t i = 0; i < size; i++)
            pdest[i] = psrc[i];
    } else {
        for (size_t i = size; i != 0; i--)
            pdest[i - 1] = psrc[i - 1];
    }

    return dest;
}

void *memset(void *buffer, uint8_t value, size_t size) {
#ifdef __x86_64__
    // use optimized memset in x86-64
    asm volatile(
        "rep stosb"
        : "=D"(buffer), "=c"(value)
        : "0"(buffer), "a"(value), "1"(size)
        : "memory");
#else
    uint8_t *pbuffer = (uint8_t *)buffer;

    for (size_t i = 0; i < size; i++)
        pbuffer[i] = (uint8_t)value;
#endif
    return buffer;
}

char *strcpy(char *dest, const char *src) {
    size_t i;

    for (i = 0; src[i]; i++)
        dest[i] = src[i];

    dest[i] = 0;

    return dest;
}

char *strncpy(char *dest, const char *src, size_t n) {
    size_t i;

    for (i = 0; i < n && src[i]; i++)
        dest[i] = src[i];
    for ( ; i < n; i++)
        dest[i] = 0;

    return dest;
}

int strcmp(const char *s1, const char *s2) {
    for (size_t i = 0; ; i++) {
        char c1 = s1[i], c2 = s2[i];
        if (c1 != c2)
            return c1 < c2 ? -1 : 1;
        if (!c1)
            return 0;
    }
}

int strncmp(const char *s1, const char *s2, size_t n) {
    for (size_t i = 0; i < n; i++) {
        char c1 = s1[i], c2 = s2[i];
        if (c1 != c2)
            return c1 < c2 ? -1 : 1;
        if (!c1)
            return 0;
    }

    return 0;
}

size_t strlen(const char *str) {
    size_t len = 0;

    while (str[len] != '\0')
        len++;

    return len;
}

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

    do {
        int digit = value % base;
        *(pbuffer++) = (digit < 10 ? '0' + digit : 'a' + digit - 10);
        value /= base;
    } while (value > 0);

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
