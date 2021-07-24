#ifndef _STDLIB_H
#define _STDLIB_H 1
 
#include <sys/cdefs.h>
 
#ifdef __cplusplus
extern "C" {
#endif
 
__attribute__((__noreturn__))
void abort(void);
int rand(void);
void srand(unsigned int seed);
int maxrand(int seed, int max);
#ifdef __cplusplus
}
#endif
 
#endif
