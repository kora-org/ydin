#include <stdio.h>
#include <stdlib.h>
#include <kernel/idt.h>

__attribute__((__noreturn__))
void panic(const char *err) {
#if defined(__is_libk)
	// TODO: Add proper kernel panic.
	printf("kernel: panic: %s\n", err);
#else
	// TODO: Abnormally terminate the process as if by SIGABRT.
	printf("%s\n", err);
#endif
	disable_idt();
	asm("hlt");
	while (1) { }
	__builtin_unreachable();
}
