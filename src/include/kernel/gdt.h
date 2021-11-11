#pragma once
#include <stdint.h>

typedef struct __attribute__((packed)) {
    uint16_t size;
    uint64_t offset;
} gdt_desc_t;

typedef struct __attribute__((packed)) {
    uint16_t limit;
    uint16_t base_low16;
    uint8_t base_mid8;
    uint8_t access;
    uint8_t granularity;
    uint8_t base_high8;
} gdt_entry_t;

typedef struct __attribute__((packed)) {
    uint16_t length;
    uint16_t base_low16;
    uint8_t base_mid8;
    uint8_t flags1;
    uint8_t flags2;
    uint8_t base_high8;
    uint32_t base_upper32;
    uint32_t reserved;
} tss_entry_t;

typedef struct __attribute__((packed)) {
    uint32_t reserved0;
    uint64_t rsp[3];
    uint64_t reserved1;
    uint64_t ist[7];
    uint32_t reserved2;
    uint32_t reserved3;
    uint16_t reserved4;
    uint16_t iopb_offset;
} tss_t;

typedef struct __attribute__((packed)) {
    gdt_entry_t null;
    gdt_entry_t kernel_code;
    gdt_entry_t kernel_data;
    gdt_entry_t user_code;
    gdt_entry_t user_data;
    tss_entry_t tss;
} gdt_t;

void gdt_init(void);
extern void gdt_flush(gdt_desc_t *gdt_desc);
extern void tss_flush(void);
