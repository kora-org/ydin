#ifndef _STDIO_H
#define _STDIO_H 1
 
#include <sys/cdefs.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stddef.h>
 
#define EOF (-1)
 
#ifdef __cplusplus
extern "C" {
#endif

#define FS_FILE       0
#define FS_DIRECTORY  1
#define FS_INVALID    2
typedef struct _FILE {
	char        name[32];
	uint32_t    flags;
	uint32_t    fileLength;
	uint32_t    id;
	uint32_t    eof;
	uint32_t    position;
	uint32_t    currentCluster;
	uint32_t    device;
} FILE, *PFILE;
int putchar(int);
int puts(const char*);
int printf_(const char* format, ...);
#define printf printf_
int sprintf_(char* buffer, const char* format, ...);
#define sprintf sprintf_
int snprintf_(char* buffer, size_t count, const char* format, ...);
#define snprintf snprintf_
int vsnprintf_(char* buffer, size_t count, const char* format, va_list va);
#define vsnprintf vsnprintf_

// use output function (instead of buffer) for streamlike interface
int fctprintf_(void (*out)(char character, void* arg), void* arg, const char* format, ...);
#define fctprintf fctprintf_

#ifdef __cplusplus
}
#endif
 
#endif
