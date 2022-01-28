/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Copyright © 2022 Leap of Azzam
 *
 * This file is part of FaruOS.
 *
 * FaruOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FaruOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FaruOS.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <string.h>

void *memchr(const void *s, int c, size_t size) {
    uint8_t *p = (uint8_t *)s;
    uint8_t cc = (uint8_t)c;

    for (size_t i = 0; i < size; i++, p++) {
        if (*p == cc)
            return p;
    }

    return NULL;
}

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
               : "=D"(dest), "=S"(src), "=c"(size)
               : "D"(dest), "S"(src), "c"(size)
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

void *memset(void *buffer, int value, size_t size) {
#ifdef __x86_64__
    // use optimized memset in x86-64
    asm volatile("rep stosb"
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

char *strchr(const char *str, int ch) {
    while (*str != (char)ch)
        if (!*str++)
            return 0;
    return (char *)str;
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

size_t strlen(const char *str) {
    size_t len = 0;

    while (str[len] != '\0')
        len++;

    return len;
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

size_t strspn(const char *s1, const char *s2) {
    size_t ret = 0;

    while (*s1 && strchr(s2, *s1++))
        ret++;

    return ret;    
}

size_t strcspn(const char *s1, const char *s2) {
    size_t ret = 0;

    while (*s1) {
        if (strchr(s2, *s1))
            return ret;
        else
            s1++, ret++;
    }

    return ret;
}

char *strtok(char *str, const char *delim) {
    char *p = 0;

    if (str)
        p = str;
    else if (!p)
        return 0;

    str = p + strspn(p, delim);
    p = str + strcspn(str, delim);
    if (p == str)
        return p = 0;

    p = *p ? *p = 0,p + 1 : 0;
    return str;
}
