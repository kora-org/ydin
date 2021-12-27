#pragma once
#include <stdint.h>
#include <stddef.h>

void *memchr(const void *s, int c, size_t size);
void *memset(void *buffer, int value, size_t size);
void *memcpy(void *dest, const void *src, size_t size);
int memcmp(const void *s1, const void *s2, size_t size);
void *memmove(void *dest, const void *src, size_t size);

char *strchr(const char *str, int ch);
char *strcpy(char *dest, const char *src);
char *strncpy(char *dest, const char *src, size_t n);
size_t strlen(const char *str);
int strcmp(const char *s1, const char *s2);
int strncmp(const char *s1, const char *s2, size_t n);
size_t strspn(const char *s1, const char *s2);
size_t strcspn(const char *s1, const char *s2);
char *strtok(char *str, const char *delim);
