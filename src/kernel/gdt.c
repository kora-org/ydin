#include <stdint.h>
#include <kernel/gdt.h>

__attribute__((aligned(0x1000)))
struct gdt gdt = {
    {0, 0, 0, 0x00, 0x00, 0},
    {0xffff, 0, 0, 0x9a, 0x80, 0},
    {0xffff, 0, 0, 0x92, 0x80, 0},
    {0xffff, 0, 0, 0x9a, 0xcf, 0},
    {0xffff, 0, 0, 0x92, 0xcf, 0},
    {0, 0, 0, 0x9a, 0xa2, 0},
    {0, 0, 0, 0x92, 0xa0, 0},
};

void init_gdt(void) {
    struct gdtdesc gdtdesc;
    gdtdesc.size = sizeof(struct gdt) - 1;
    gdtdesc.offset = (uint64_t)&gdt;
 
    gdt_flush(&gdtdesc);
}
