#pragma once
#include <stdint.h>
#include <stddef.h>

char *itoa(int value, char *buffer, int base);
int atoi(const char* str);

void *memset(void *buffer, int value, size_t size);
void *memcpy(void *dest, const void *src, size_t size);
int memcmp(const void *s1, const void *s2, size_t size);
void *memmove(void *dest, const void *src, size_t size);

char *strcpy(char *dest, const char *src);
char *strncpy(char *dest, const char *src, size_t n);
size_t strlen(const char *str);
int strcmp(const char *s1, const char *s2);
int strncmp(const char *s1, const char *s2, size_t n);
