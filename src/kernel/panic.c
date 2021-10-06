#include <stdio.h>
#include <kernel/kernel.h>
#include <kernel/panic.h>

void panic(const char* msg) {
    uint8_t* rip = __builtin_return_address(0);
    uint64_t* rbp = __builtin_frame_address(0);
    printf("\n");
    printf("[kernel] Panic: %s\n", msg);
    printf("[kernel] \n");
    printf("[kernel] Stack trace:\n");
    while(rbp) {
        printf("[kernel] %p %p\n", &rip, &rbp);
        rip = *(rbp - 1);
        rbp = *(rbp + 0);
    }
    printf("[kernel] \n");
    printf("[kernel] System halted");
    for (;;) {
        halt();
    }
}
