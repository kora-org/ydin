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

#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <kernel/bitmap.h>
#include <kernel/pmm.h>
#include <kernel/kernel.h>

struct pmm pmm_info;
bitmap_t *bitmap;
size_t highest_page;

void pmm_init(struct stivale2_struct *stivale2_struct) {
    log("Initializing PMM...\n");

    struct stivale2_struct_tag_memmap *memory_map = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_MEMMAP_ID);
    pmm_info.memory_map = memory_map;
    struct stivale2_mmap_entry *current_entry;

    log("Memory map layout:\n");

    size_t top = 0;
    for (uint64_t i = 0; i < pmm_info.memory_map->entries; i++) {
        current_entry = &pmm_info.memory_map->memmap[i];

        log("Entry %d: base=0x%.16llX, length=0x%.16llX, type=%s\n", i + 1, current_entry->base, current_entry->length, mmap_get_entry_type(current_entry->type));

        if (current_entry->type != STIVALE2_MMAP_USABLE &&
            current_entry->type != STIVALE2_MMAP_BOOTLOADER_RECLAIMABLE &&
            current_entry->type != STIVALE2_MMAP_KERNEL_AND_MODULES)
            continue;

        top = current_entry->base + current_entry->length;

        if (top > highest_page)
            highest_page = top;
    }

    pmm_info.memory_size = highest_page;
    pmm_info.max_pages = KB_TO_PAGES(pmm_info.memory_size);
    pmm_info.used_pages = pmm_info.max_pages;

    size_t bitmap_size = ALIGN_UP((highest_page / PAGE_SIZE) / 8, PAGE_SIZE);

    bitmap->size = bitmap_size;

    log("Memory specifications:\n");
    current_entry = &pmm_info.memory_map->memmap[0];
    log("Total amount of used memory: %d kB\n", (current_entry->base + current_entry->length - 1) / 1024);
    log("Bitmap size: %d kB\n", bitmap->size / 1024);

    for (uint64_t i = 0; i < pmm_info.memory_map->entries; i++) {
        current_entry = &pmm_info.memory_map->memmap[i];

        if (current_entry->type == STIVALE2_MMAP_USABLE && current_entry->length >= bitmap->size) {
            bitmap->map = (uint8_t *)(current_entry->base + KERNEL_DATA_OFFSET);

            memset((void *)bitmap->map, 0xFF, bitmap->size);

            current_entry->base += bitmap->size;
            current_entry->length -= bitmap->size;

            break;
        }
    }

    for (uint64_t i = 0; i < pmm_info.memory_map->entries; i++) {
        current_entry = &pmm_info.memory_map->memmap[i];

        if (current_entry->type == STIVALE2_MMAP_USABLE)
            pmm_free((void *)current_entry->base, current_entry->length / PAGE_SIZE);
    }

    log("PMM initialized!\n");
}

const char *mmap_get_entry_type(uint32_t type) {
    switch (type) {
        case STIVALE2_MMAP_USABLE: return "USABLE";
        case STIVALE2_MMAP_RESERVED: return "RESERVED";
        case STIVALE2_MMAP_ACPI_RECLAIMABLE: return "ACPI_RECLAIMABLE";
        case STIVALE2_MMAP_ACPI_NVS: return "ACPI_NON_VOLATILE_STORAGE";
        case STIVALE2_MMAP_BAD_MEMORY: return "BAD_MEMORY";
        case STIVALE2_MMAP_BOOTLOADER_RECLAIMABLE: return "BOOTLOADER_RECLAIMABLE";
        case STIVALE2_MMAP_KERNEL_AND_MODULES: return "KERNEL_AND_MODULES";
        case STIVALE2_MMAP_FRAMEBUFFER: return "FRAMEBUFFER";
        default: return "UNKNOWN";
    }
}

static void *pmm_inner_alloc(size_t count) {
    if (count == 0)
        return NULL;

    for (size_t h = 0; h < count; h++) {
        for (size_t i = 0; i < PAGE_TO_BIT(highest_page); i++) {
            if (!bitmap_check(bitmap, i))
                return (void *)BIT_TO_PAGE(i);
        }
    }

    return NULL;
}

void *pmm_alloc(size_t count) {
    if (pmm_info.used_pages <= 0)
        return NULL;

    void *pointer = pmm_inner_alloc(count);

    if (pointer == NULL)
        return NULL;

    uint64_t index = (uint64_t)pointer / PAGE_SIZE;

    for (size_t i = 0; i < count; i++)
        bitmap_set(bitmap, index + i);

    pmm_info.used_pages += count;

    return (void *)((index * PAGE_SIZE) + KERNEL_DATA_OFFSET);
}

void *pmm_alloc_zero(size_t count) {
    void *ret = pmm_alloc(count);
    memset(ret, 0, count * PAGE_SIZE);
    return ret;
}

void pmm_free(void *pointer, size_t count) {
    uint64_t page = (uint64_t)pointer / PAGE_SIZE;

    for (size_t i = 0; i < page + count; i++)
        bitmap_unset(bitmap, i);

    pmm_info.used_pages -= count;
}
