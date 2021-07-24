#include <kernel/io.h>
#include <kernel/pit.h>

void init_pit(int hz) {
    int divisor = 1193180 / hz;

    outb(0x43, 0x36);
    outb(0x40, divisor & 0xff);
    outb(0x40, divisor >> 8);
}
