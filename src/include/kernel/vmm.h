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

#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stivale2.h>
#include <kernel/mm.h>

#define GB 0x40000000UL
#define PTE_PRESENT (1 << 0)
#define PTE_READ_WRITE (1 << 1)
#define PTE_USER_SUPERVISOR (1 << 2)
#define PTE_WRITE_THROUGH (1 << 3)
#define PTE_CACHE_DISABLED (1 << 4)
#define PTE_ACCESSED (1 << 5)
#define PTE_DIRTY (1 << 6)
#define PTE_PAT (1 << 7)
#define PTE_GLOBAL (1 << 8)
#define PTE_UNAVAILABLE (1 << 63)

void vmm_init(struct stivale2_struct *stivale2_struct);
uint64_t *vmm_create_page_dir(void);
void vmm_map_page(uint64_t *vmm, uintptr_t physical_address, uintptr_t virtual_address, int flags);
void vmm_flush_tlb(uintptr_t address);
void vmm_activate_page_dir(uint64_t *vmm);
