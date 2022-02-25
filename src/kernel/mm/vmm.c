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
#include <string.h>
#include <kernel/pmm.h>
#include <kernel/vmm.h>
#include <kernel/kernel.h>

static uint64_t *root_page_dir;
static uint8_t is_la57_enabled = 0;

static uint8_t check_la57(void) {
    uint64_t cr4;
    asm volatile("mov %%cr4, %0" : "=rax"(cr4));
    return (cr4 >> 12) & 1;
}

void vmm_init(struct stivale2_struct *stivale2_struct) {
    log("Initializing VMM...\n");

    struct stivale2_struct_tag_memmap *memory_map = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_MEMMAP_ID);
    struct stivale2_struct_tag_pmrs *pmr_tag = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_PMRS_ID);
    struct stivale2_pmr *pmrs = pmr_tag->pmrs;
    root_page_dir = vmm_create_page_dir();

    if (check_la57()) {
        is_la57_enabled = 1;
        log("5-level paging supported!\n");
    }

    // 1/4: map stivale2 structs
    for (uint64_t i = 0; i < memory_map->entries; i++) {
        struct stivale2_mmap_entry *current_entry = &memory_map->memmap[i];

        if (current_entry->type == STIVALE2_MMAP_USABLE || current_entry->type == STIVALE2_MMAP_BOOTLOADER_RECLAIMABLE || current_entry->type == STIVALE2_MMAP_FRAMEBUFFER) {
            for (uint64_t j = 0; j < memory_map->memmap[i].length; j += PAGE_SIZE) {
                vmm_map_page(root_page_dir, j, j + KERNEL_DATA_OFFSET, PTE_PRESENT | PTE_READ_WRITE);
            }
        }
    }

    // 2/4: map 2 GB of kernel data
    for (uint64_t i = 0; i < 2 * GB; i += PAGE_SIZE) {
        log("mapping kernel data\n");
        vmm_map_page(root_page_dir, i, i + KERNEL_DATA_OFFSET, PTE_PRESENT | PTE_READ_WRITE);
    }

    // 3/4: map 2 GB of kernel code
    for (uint64_t i = 0; i < 2 * GB; i += PAGE_SIZE) {
        log("mapping kernel code\n")
        vmm_map_page(root_page_dir, i, i + KERNEL_CODE_OFFSET, PTE_PRESENT | PTE_READ_WRITE);
    }

    // 4/4: map protected memory ranges
    for (size_t i = 0; i < pmr_tag->entries; i++) {
        uint64_t virt = pmrs[i].base;
        uint64_t phys = PHYSICAL_ADDRESS + (virt - VIRTUAL_ADDRESS);

        for (uint64_t j = 0; j < 0x80000000; j += PAGE_SIZE)
            vmm_map_page(root_page_dir, phys + j, virt + j, PTE_PRESENT | PTE_READ_WRITE);
    }

    vmm_activate_page_dir(root_page_dir);
    log("VMM initialized\n");
}

uint64_t *vmm_create_page_dir(void) {
    return (uint64_t *)pmm_alloc_zero(1);
}

static uint64_t *vmm_get_next_level(uint64_t *pml, size_t index, int flags) {
    if (!(pml[index] & 1)) {
        pml[index] = (uint64_t)pmm_alloc_zero(1);
        pml[index] |= flags;
    }

    return (uint64_t *)(pml[index] & ~(0x1ff));
}

void vmm_map_page(uint64_t *page_dir, uintptr_t physical_address, uintptr_t virtual_address, int flags) {
    if (is_la57_enabled)
        goto la57;

    size_t index4 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 39)) >> 39;
    size_t index3 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 30)) >> 30;
    size_t index2 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 21)) >> 21;
    size_t index1 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 12)) >> 12;

    uint64_t *pml3 = vmm_get_next_level(page_dir, index4, flags);
    uint64_t *pml2 = vmm_get_next_level(pml3, index3, flags);
    uint64_t *pml1 = vmm_get_next_level(pml2, index2, flags);

    pml1[index1] = physical_address | flags;

la57: {
    size_t index5 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 48)) >> 48;
    size_t index4 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 39)) >> 39;
    size_t index3 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 30)) >> 30;
    size_t index2 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 21)) >> 21;
    size_t index1 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 12)) >> 12;

    uint64_t *pml4 = vmm_get_next_level(page_dir, index5, flags);
    uint64_t *pml3 = vmm_get_next_level(pml4, index4, flags);
    uint64_t *pml2 = vmm_get_next_level(pml3, index3, flags);
    uint64_t *pml1 = vmm_get_next_level(pml2, index2, flags);

    pml1[index1] = physical_address | flags;
}
    vmm_flush_tlb(virtual_address);
}

void vmm_unmap_page(uint64_t *page_dir, uintptr_t virtual_address, int flags) {
    if (is_la57_enabled)
        goto la57;

    size_t index4 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 39)) >> 39;
    size_t index3 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 30)) >> 30;
    size_t index2 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 21)) >> 21;
    size_t index1 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 12)) >> 12;

    uint64_t *pml3 = vmm_get_next_level(page_dir, index4, flags);
    uint64_t *pml2 = vmm_get_next_level(pml3, index3, flags);
    uint64_t *pml1 = vmm_get_next_level(pml2, index2, flags);

    pml1[index1] = 0;

la57: {
    size_t index5 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 48)) >> 48;
    size_t index4 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 39)) >> 39;
    size_t index3 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 30)) >> 30;
    size_t index2 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 21)) >> 21;
    size_t index1 = (size_t)(virtual_address & ((uintptr_t)0x1FF << 12)) >> 12;

    uint64_t *pml4 = vmm_get_next_level(page_dir, index5, flags);
    uint64_t *pml3 = vmm_get_next_level(pml4, index4, flags);
    uint64_t *pml2 = vmm_get_next_level(pml3, index3, flags);
    uint64_t *pml1 = vmm_get_next_level(pml2, index2, flags);

    pml1[index1] = 0;
}
    vmm_flush_tlb(virtual_address);
}

void vmm_flush_tlb(uintptr_t address) {
    asm volatile("invlpg (%0)" : : "r" (address));
}

void vmm_activate_page_dir(uint64_t *page_dir) {
    asm volatile("mov %0, %%cr3" : : "r" ((uint64_t)page_dir) : "memory");
}
