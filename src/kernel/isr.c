#include <stdint.h>
#include <kernel/panic.h>
#include <kernel/kernel.h>
#include <kernel/isr.h>

static char *exceptions[] = {
    [0] = "Division-by-zero",
    [1] = "Debug",
    [2] = "Non-maskable interrupt",
    [3] = "Breakpoint",
    [4] = "Overflow",
    [5] = "Bound range exceeded",
    [6] = "Invalid opcode",
    [7] = "Device not available",
    [8] = "Double fault",
    [9] = "Coprocessor segment overrun",
    [10] = "Invalid TSS",
    [11] = "Segment not present",
    [12] = "Stack fault",
    [13] = "General protection fault",
    [14] = "Page fault",
    [16] = "x87 floating-point exception",
    [17] = "Alignment check",
    [18] = "Machine check",
    [19] = "SIMD floating-point exception",
    [20] = "Virtualization exception",
    [30] = "Security exception"
};

void isr_handler(uint64_t irq) {
    __asm__("cli");
    panic((char *)exceptions[irq]);
    for (;;) {
        halt();
    }
}

void isr_0(void) {
    isr_handler(0);
};

void isr_1(void) {
    isr_handler(1);
};

void isr_2(void) {
    isr_handler(2);
};

void isr_3(void) {
    isr_handler(3);
};

void isr_4(void) {
    isr_handler(4);
};

void isr_5(void) {
    isr_handler(5);
};

void isr_6(void) {
    isr_handler(6);
};

void isr_7(void) {
    isr_handler(7);
};

void isr_8(void) {
    isr_handler(8);
};

void isr_9(void) {
    isr_handler(9);
}

void isr_10(void) {
    isr_handler(10);
};

void isr_11(void) {
    isr_handler(11);
};

void isr_12(void) {
    isr_handler(12);
};

void isr_13(void) {
    isr_handler(13);
};

void isr_14(void) {
    isr_handler(14);
};

void isr_16(void) {
    isr_handler(16);
};

void isr_17(void) {
    isr_handler(17);
};

void isr_18(void) {
    isr_handler(18);
};

void isr_19(void) {
    isr_handler(19);
};

void isr_20(void) {
    isr_handler(20);
};

void isr_30(void) {
    isr_handler(30);
};

void isr_reserved(void) {
    // do nothing
}
