#include <stdio.h>
#include <stdlib.h>
 
__attribute__((__noreturn__))
void abort(void) {
	// TODO: Abnormally terminate the process as if by SIGABRT.
	printf("abort()\n");
	__builtin_unreachable();
}
