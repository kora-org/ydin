#pragma once
#include <stdint.h>

struct gdt_desc_t {
    uint16_t size;
    uint64_t offset;
} __attribute__((packed));

struct gdt_entry_t {
    uint16_t limit0;
    uint16_t base0;
    uint8_t base1;
    uint8_t access;
    uint8_t limit1_flags;
    uint8_t base2;
} __attribute__((packed));

struct gdt_t {
    struct gdt_entry_t null;
    struct gdt_entry_t kernel_code;
    struct gdt_entry_t kernel_data;
    struct gdt_entry_t user_null;
    struct gdt_entry_t user_code;
    struct gdt_entry_t user_data;
    struct gdt_entry_t reserved;
} __attribute__((packed))
__attribute((aligned(0x1000)));

void gdt_init(void);
extern void gdt_flush(struct gdt_desc_t *gdt_desc);
