#include <stdio.h>
#include <stdlib.h>
#include <kernel/idt.h>

__attribute__((__noreturn__))
void panic(const char *err) {
#if defined(__is_libk)
	// TODO: Add proper kernel panic.
	printf("\n------------------------------------------------------\n");
	printf("                     KERNEL PANIC                     \n");
	printf("------------------------------------------------------\n");
	printf("An error has occured. To prevent major problems to the\n");
	printf("operating system, the system will halt and you meed to\n");
	printf("restart your computer.                                \n\n");
	printf("Cause: %s\n", err);
#else
	// TODO: Abnormally terminate the process as if by SIGABRT.
	printf("%s\n", err);
#endif
	disable_idt();
	asm("hlt");
	__builtin_unreachable();
}
