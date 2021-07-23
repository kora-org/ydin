#include <stdint.h>

struct gdt_ptr
{
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));

void print_gdt_ent(uint64_t* ent);
void print_gdt();
void load_gdt();
