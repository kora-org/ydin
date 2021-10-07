#pragma once
#include <stdint.h>

typedef struct __attribute__((packed)) {
    uint16_t size;
    uint64_t offset;
} gdt_desc_t;

typedef struct __attribute__((packed)) {
    uint16_t limit0;
    uint16_t base0;
    uint8_t base1;
    uint8_t access;
    uint8_t limit1_flags;
    uint8_t base2;
} gdt_entry_t;

typedef struct __attribute__((packed)) {
    struct gdt_entry_t null;
    struct gdt_entry_t kernel_code;
    struct gdt_entry_t kernel_data;
    struct gdt_entry_t user_null;
    struct gdt_entry_t user_code;
    struct gdt_entry_t user_data;
    struct gdt_entry_t reserved;
} gdt_t;

void gdt_init(void);
extern void gdt_flush(struct gdt_desc_t *gdt_desc);
