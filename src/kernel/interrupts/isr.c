#include <stdint.h>
#include <kernel/panic.h>
#include <kernel/kernel.h>
#include <kernel/isr.h>

void isr_handler(uint64_t irq, exception_t *rsp) {
    isr_panic(rsp, "Exception occurred");
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
