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
    panic((char *)exceptions[irq]);
}

EXCEPTION(0)
EXCEPTION(1)
EXCEPTION(2)
EXCEPTION(3)
EXCEPTION(4)
EXCEPTION(5)
EXCEPTION(6)
EXCEPTION(7)
EXCEPTION(8)
EXCEPTION(9)
EXCEPTION(10)
EXCEPTION(11)
EXCEPTION(12)
EXCEPTION(13)
EXCEPTION(14)
EXCEPTION(15)
EXCEPTION(16)
EXCEPTION(17)
EXCEPTION(18)
EXCEPTION(19)
EXCEPTION(20)
EXCEPTION(30)
void isr_reserved(void) {}
