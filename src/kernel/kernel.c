/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Copyright © 2022 Leap of Azzam
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

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stivale2.h>
#include <kernel/mm.h>
#include <kernel/cpu.h>
#include <kernel/gdt.h>
#include <kernel/idt.h>
#include <kernel/pic.h>
#include <kernel/pmm.h>
#include <kernel/vmm.h>
#include <kernel/panic.h>
#include <kernel/kernel.h>

uint8_t stack[STACK_SIZE];

struct stivale2_struct *stivale2;
struct stivale2_struct_tag_framebuffer *fb_tag;
struct stivale2_struct_tag_smp *smp_tag;
struct stivale2_struct_tag_kernel_base_address *kernel_base;

int term_cols;
int term_rows;

void (*term_write)(const char *string, size_t length);

static struct stivale2_tag la57_hdr_tag = {
    .identifier = STIVALE2_HEADER_TAG_5LV_PAGING_ID,
    .next = 0
};

static struct stivale2_header_tag_smp smp_hdr_tag = {
    .tag = {
        .identifier = STIVALE2_HEADER_TAG_SMP_ID,
        .next = (uint64_t)&la57_hdr_tag
    },
    .flags = 0
};

static struct stivale2_header_tag_terminal terminal_hdr_tag = {
    .tag = {
        .identifier = STIVALE2_HEADER_TAG_TERMINAL_ID,
        .next = (uint64_t)&smp_hdr_tag
    },
    .flags = 0
};

static struct stivale2_header_tag_framebuffer framebuffer_hdr_tag = {
    .tag = {
        .identifier = STIVALE2_HEADER_TAG_FRAMEBUFFER_ID,
        .next = (uint64_t)&terminal_hdr_tag
    },
    .framebuffer_width = 0,
    .framebuffer_height = 0,
    .framebuffer_bpp = 0
};

__attribute__((section(".stivale2hdr"), used))
static struct stivale2_header stivale_hdr = {
    .entry_point = 0,
    .stack = (uintptr_t)stack + sizeof(stack),
    .flags = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4),
    .tags = (uintptr_t)&framebuffer_hdr_tag
};

void *stivale2_get_tag(struct stivale2_struct *stivale2_struct, uint64_t id) {
    struct stivale2_tag *current_tag = (void *)stivale2_struct->tags;
    for (;;) {
        if (current_tag == NULL) {
            return NULL;
        }
        if (current_tag->identifier == id) {
            return current_tag;
        }
        current_tag = (void *)current_tag->next;
    }
}

void __log(const char *file, int line, const char *str, ...) {
    va_list args;
    va_start(args, str);
    printf("[%s:%d] ", file, line);
    vprintf(str, args);
    va_end(args);
}

void halt(void) {
    asm("hlt");
}

void _start(struct stivale2_struct *stivale2_struct) {
    stivale2 = stivale2_struct;

    struct stivale2_struct_tag_terminal *terminal_tag;
    terminal_tag = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_TERMINAL_ID);
    fb_tag = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_FRAMEBUFFER_ID);
    smp_tag = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_SMP_ID);
    kernel_base = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_KERNEL_BASE_ADDRESS_ID);

    if (terminal_tag == NULL) {
        for (;;) {
            asm ("hlt");
        }
    }

    void *term_write_ptr = (void *)terminal_tag->term_write;
    term_write = term_write_ptr;
    term_cols = terminal_tag->cols;
    term_rows = terminal_tag->rows;

    log("FaruOS version %s\n", __faruos_version__);
    log("Compiled in %s at %s with %s\n", __DATE__, __TIME__, __VERSION__);
    gdt_init();
    idt_init();
    pmm_init(stivale2_struct);
    vmm_init(stivale2_struct);
    pic_remap();
    printf("Hello World!\n");
    uint64_t *test = vmm_create_page_dir();
    printf("my vmm page: 0x%p\n", test);
    //panic("panic test");

    for (;;) {
        halt();
    }
}
