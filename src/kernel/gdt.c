#include <stdint.h>
#include <kernel/gdt.h>

__attribute__((aligned(0x1000)))
struct gdt_t gdt = {
    {0, 0, 0, 0x00, 0x00, 0},
    {0xffff, 0, 0, 0x9a, 0x80, 0},
    {0xffff, 0, 0, 0x92, 0x80, 0},
    {0xffff, 0, 0, 0x9a, 0xcf, 0},
    {0xffff, 0, 0, 0x92, 0xcf, 0},
    {0, 0, 0, 0x9a, 0xa2, 0},
    {0, 0, 0, 0x92, 0xa0, 0},
};

void gdt_init(void) {
    struct gdt_desc_t gdt_desc;
    gdt_desc.size = sizeof(struct gdt_t) - 1;
    gdt_desc.offset = (uint64_t)&gdt;
 
    gdt_flush(&gdt_desc);
}
