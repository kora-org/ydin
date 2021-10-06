#pragma once
#include <stdint.h>

struct gdtdesc {
    uint16_t size;
    uint64_t offset;
} __attribute__((packed));

struct gdtentry {
    uint16_t limit0;
    uint16_t base0;
    uint8_t base1;
    uint8_t access;
    uint8_t limit1_flags;
    uint8_t base2;
} __attribute__((packed));

struct gdt {
    struct gdtentry null;
    struct gdtentry kernel_code;
    struct gdtentry kernel_data;
    struct gdtentry user_null;
    struct gdtentry user_code;
    struct gdtentry user_data;
    struct gdtentry reserved;
} __attribute__((packed))
__attribute((aligned(0x1000)));

void init_gdt(void);
extern void gdt_flush(struct gdtdesc *gdtdesc);
