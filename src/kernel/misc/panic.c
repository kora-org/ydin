#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <kernel/kernel.h>
#include <kernel/isr.h>
#include <kernel/panic.h>

void __panic(char *file, const char function[20], int line, int is_isr, exception_t *exception, char *message, ...) {
    va_list args;
    va_start(args, message);

    static bool is_panic;
    if (!is_panic) {
        is_panic = true;
    } else {
        log("\nYo dawg, I heard you like kernel panic. So I put a kernel panic in\n");
        log("your kernel panic so you can panic while you panic!\n");
        printf("[kernel]");
    }
    uint8_t* rip = __builtin_return_address(0);
    uint64_t* rbp = __builtin_frame_address(0);
    printf("\n");
    if (is_isr == 0)
        log("Kernel panic: %s\n", message);
    else
        log("Kernel panic: Exception occured\n");
    vprintf(message, args);
    va_end(args);
    if (is_isr == 0) {
        log("In %s() at line %d in %s\n", function, line, file);
        log("\n");
        log("Stack trace:\n");
        while (rbp) {
            log("    0x%.16llx\n", &rip);
            rip = *(rbp - 1);
            rbp = *(rbp + 0);
        }
        log("\n");
    } else {
        log("Exception: %s", exceptions[exception->isr_number]);
        log("Error code: 0x%.16llx", exception->error_code);
        log("Register dump:");
        log("\trax: 0x%.16llx, rbx:    0x%.16llx, rcx: 0x%.16llx, rdx: 0x%.16llx\n"
            "[kernel] \trsi: 0x%.16llx, rdi:    0x%.16llx, rbp: 0x%.16llx, r8 : 0x%.16llx\n"
            "[kernel] \tr9:  0x%.16llx, r10:    0x%.16llx, r11: 0x%.16llx, r12: 0x%.16llx\n"
            "[kernel] \tr13: 0x%.16llx, r14:    0x%.16llx, r15: 0x%.16llx, ss : 0x%.16llx\n"
            "[kernel] \trsp: 0x%.16llx, rflags: 0x%.16llx, cs : 0x%.16llx, rip: 0x%.16llx\n",
            exception->rax, exception->rbx,    exception->rcx, exception->rdx,
            exception->rsi, exception->rdi,    exception->rbp, exception->r8,
            exception->r9,  exception->r10,    exception->r11, exception->r12,
            exception->r13, exception->r14,    exception->r15, exception->ss,
            exception->rsp, exception->rflags, exception->cs,  exception->rip);

    }
    log("System halted");
    asm("cli");
    for (;;) {
        halt();
    }
}
