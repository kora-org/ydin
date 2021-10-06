#include <stdio.h>
#include <kernel/kernel.h>
#include <kernel/panic.h>

void panic(const char* msg) {
    uint8_t* rip = __builtin_return_address(0);
    uint64_t* rbp = __builtin_frame_address(0);
    printf("\n[kernel] panic: %s\n", msg);
    printf("Stack trace:\n");
    while(rbp) {
        printf("%p ", &rip);
        printf("%p ", &rbp);
        printf("\n");
        rip = *(rbp - 1);
        rbp = *(rbp + 0);
    }
    printf("\n\nSystem halted");
    for (;;) {
        halt();
    }
}
