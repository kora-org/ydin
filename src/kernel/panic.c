#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <kernel/kernel.h>
#include <kernel/panic.h>

void __panic(char *file, const char function[20], int line, char *message) {
    static bool is_panic;
    if (!is_panic) {
        is_panic = true;
    } else {
        printf("\n");
        printf("[kernel] Yo dawg, I heard you like kernel panic. So I put a kernel panic in\n");
        printf("[kernel] your kernel panic so you can panic while you panic!\n");
        printf("[kernel]");
    }
    uint8_t* rip = __builtin_return_address(0);
    uint64_t* rbp = __builtin_frame_address(0);
    printf("\n");
    printf("[kernel] Kernel panic: %s\n", message);
    printf("[kernel] In %s() at line %d in %s\n", function, line, file);
    printf("[kernel] \n");
    printf("[kernel] Stack trace:\n");
    while (rbp) {
        printf("[kernel]     %p\n", &rip);
        rip = *(rbp - 1);
        rbp = *(rbp + 0);
    }
    printf("[kernel] \n");
    printf("[kernel] System halted");
    asm("cli");
    for (;;) {
        halt();
    }
}
