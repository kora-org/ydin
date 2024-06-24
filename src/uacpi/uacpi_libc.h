#pragma once
#include <stdint.h>
#include <stddef.h>

#define UACPI_PRIx64 "lx"
#define UACPI_PRIX64 "lX"
#define UACPI_PRIu64 "lu"

#define PRIx64 UACPI_PRIx64
#define PRIX64 UACPI_PRIX64
#define PRIu64 UACPI_PRIu64

void *_memcpy(void *dest, const void* src, size_t size);
void *_memset(void *dest, int src, size_t size);
int _memcmp(const void *src1, const void *src2, size_t size);
void *_memmove(void *dest, const void* src, size_t size);
int _strncmp(const char *src1, const char *src2, size_t size);
int _strcmp(const char *src1, const char *src2);
size_t _strnlen(const char *src, size_t size);
size_t _strlen(const char *src);

#define uacpi_memcpy _memcpy
#define uacpi_memset _memset
#define uacpi_memcmp _memcmp
#define uacpi_memmove _memmove
#define uacpi_strncmp _strncmp
#define uacpi_strcmp _strcmp
#define uacpi_strnlen _strnlen
#define uacpi_strlen _strlen

#define uacpi_offsetof(t, m) ((uintptr_t)(&((t*)0)->m))