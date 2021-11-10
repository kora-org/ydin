#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stdarg.h>

int putc(const char c);
int putchar(char c);
int puts(const char* str);
int printf(const char* format, ...) ;
int sprintf(char* buffer, const char* format, ...);
int vsprintf(char* buffer, const char* format, va_list va);
int snprintf(char* buffer, size_t count, const char* format, ...) ;
int vsnprintf(char* buffer, size_t count, const char* format, va_list va);
int vprintf(const char* format, va_list va);
int fctprintf(void (*out)(char character, void* arg), void* arg, const char* format, ...);
int vfctprintf(void (*out)(char character, void* arg), void* arg, const char* format, va_list va);
