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

typedef struct {
    uint16_t base_low;
    uint16_t cs;
    uint8_t ist;
    uint8_t attributes;
    uint16_t base_mid;
    uint32_t base_high;
    uint32_t rsv0;
} __attribute__((packed)) idt_entry_t;

typedef struct {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed)) idtr_t;

void idt_set_descriptor(uint8_t vector, void* isr, uint8_t flags);
void idt_init(void);

static inline void enable_interrupts() {
    asm volatile ("sti");
}

static inline void disable_interrupts() {
    asm volatile ("cli");
}
