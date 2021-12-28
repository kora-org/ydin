/*
 * Copyright © 2021 Leap of Azzam
 *
 * This file is part of FaruOS.
 *
 * FaruOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FaruOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FaruOS.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once
#include <stdint.h>

typedef struct __attribute__((packed)) {
    uint16_t size;
    uint64_t offset;
} gdt_pointer_t;

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
    uint8_t flags0;
    uint8_t flags1;
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
    gdt_entry_t _16bit_code;
    gdt_entry_t _16bit_data;
    gdt_entry_t _32bit_code;
    gdt_entry_t _32bit_data;
    gdt_entry_t _64bit_code;
    gdt_entry_t _64bit_data;
    gdt_entry_t user_data;
    gdt_entry_t user_code;
    tss_entry_t tss;
} gdt_t;

void gdt_init(void);
void tss_init(void);
void tss_set_stack(uintptr_t stack);
extern void gdt_flush(gdt_pointer_t *);
extern void tss_flush(void);
