#include <stdio.h>
#include <kernel/kernel.h>

int putc(const char c) {
    term_write(&c, 1);
    return 0;
}

int putchar(char c) {
    term_write(&c, 1);
    return 0;
}

int puts(const char* str) {
    while (*str)
        putc(*str++);
    return 0;
}
