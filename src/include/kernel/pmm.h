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
#include <stivale2.h>
#include <kernel/mm.h>
#include <kernel/bitmap.h>

struct pmm {
    size_t memory_size;
    uint32_t max_pages;
    uint32_t used_pages;
    struct stivale2_struct_tag_memmap *memory_map;
};

void pmm_init(struct stivale2_struct *stivale2_struct);
const char *mmap_get_entry_type(uint32_t type);
void *pmm_find_first_free_page(size_t count);
void *pmm_alloc(size_t count);
void *pmm_alloc_zero(size_t count);
void pmm_free(void *pointer, size_t count);
