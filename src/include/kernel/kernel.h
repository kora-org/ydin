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
#include <stddef.h>
#include <stivale2.h>

#define PAGE_SIZE 4096
#define STACK_SIZE 65536

extern uint8_t stack[STACK_SIZE];

extern struct stivale2_struct *stivale2;
extern struct stivale2_struct_tag_framebuffer *fb_tag;
extern struct stivale2_struct_tag_smp *smp_tag;
extern struct stivale2_struct_tag_kernel_base_address *kernel_base;

extern int term_cols;
extern int term_rows;

extern void (*term_write)(const char *string, size_t length);
void *stivale2_get_tag(struct stivale2_struct *stivale2_struct, uint64_t id);
void halt(void);
void __log(const char *file, int line, const char *str, ...);
#define log(str...) __log(__FILE_NAME__, __LINE__, str);

#define PHYSICAL_ADDRESS kernel_base->physical_base_address
#define VIRTUAL_ADDRESS kernel_base->virtual_base_address
