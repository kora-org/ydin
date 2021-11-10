#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <kernel/pmm.h>
#include <kernel/kernel.h>

struct pmm pmm_info;
bitmap_t *bitmap;
size_t highest_page;

void pmm_init(struct stivale2_struct *stivale2_struct) {
    struct stivale2_struct_tag_memmap *memory_map = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_MEMMAP_ID);
    pmm_info.memory_map = memory_map;
    struct stivale2_mmap_entry *current_entry;

    log("Memory map layout:\n");

    size_t top = 0;
    for (uint64_t i = 0; i < pmm_info.memory_map->entries; i++) {
        current_entry = &pmm_info.memory_map->memmap[i];

        log("- Memory map entry No. %d:\n", i);
        log("  Base: 0x%.16llx, Length: 0x%.16llx, Type: %s\n", current_entry->base, current_entry->length, get_mmap_entry_type(current_entry->type));

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

    size_t bitmap_byte_size = ALIGN_UP(ALIGN_DOWN(highest_page, PAGE_SIZE) / PAGE_SIZE / 8, PAGE_SIZE);

    bitmap->size = bitmap_byte_size;

    log("Memory specifications:\n");
    current_entry = &pmm_info.memory_map->memmap[0];
    log("- Total amount of memory: %d MB\n", (current_entry->base + current_entry->length - 1) / 1024);
    log("- Size of bitmap: %d kB\n", bitmap->size / 1024);

    log("Initializing PMM...");
    for (int i = 0; i < term_cols - (strlen("[kernel] Initializing PMM") + strlen("...")) - strlen("OK "); i++) {
        printf(" ");
    }

    for (uint64_t i = 0; i < pmm_info.memory_map->entries; i++) {
        current_entry = &pmm_info.memory_map->memmap[i];

        if (current_entry->type == STIVALE2_MMAP_USABLE)
            continue;

        if (current_entry->length >= bitmap->size) {
            bitmap->map = (uint8_t *)(TO_VIRTUAL_ADDRESS(current_entry->base));

            //memset((void *)bitmap->map, 0xFF, bitmap->size);

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

    bitmap_set(bitmap, 0);
    printf("\033[32mOK\033[0m\n");
}

const char *get_mmap_entry_type(uint32_t type) {
    switch (type) {
        case STIVALE2_MMAP_USABLE: return "Usable";
        case STIVALE2_MMAP_RESERVED: return "Reserved";
        case STIVALE2_MMAP_ACPI_RECLAIMABLE: return "ACPI Reclaimable";
        case STIVALE2_MMAP_ACPI_NVS: return "ACPI Non Volatile Storage";
        case STIVALE2_MMAP_BAD_MEMORY: return "Bad Memory";
        case STIVALE2_MMAP_BOOTLOADER_RECLAIMABLE: return "Bootloader Reclaimable";
        case STIVALE2_MMAP_KERNEL_AND_MODULES: return "Kernel And Modules";
        case STIVALE2_MMAP_FRAMEBUFFER: return "Framebuffer";
        default: return "Unknown";
    }
}

void *pmm_find_first_free_page(size_t page_count) {
    if (page_count == 0)
        return NULL;

    for (size_t counter = 0; counter < page_count; counter++) {
        for (size_t i = 0; i < PAGE_TO_BIT(highest_page); i++) {
            if (!bitmap_check(bitmap, i))
                return (void *)BIT_TO_PAGE(i);
        }
    }

    return NULL;
}

void *pmm_alloc(size_t page_count) {
    if (pmm_info.used_pages <= 0)
        return NULL;

    void *pointer = pmm_find_first_free_page(page_count);

    if (pointer == NULL)
        return NULL;

    uint64_t index = (uint64_t)pointer / PAGE_SIZE;

    for (size_t i = 0; i < page_count; i++)
        bitmap_set(bitmap, index + i);

    pmm_info.used_pages += page_count;

    return (void *)(uint64_t)(TO_VIRTUAL_ADDRESS(index * PAGE_SIZE));
}

void pmm_free(void *pointer, size_t page_count) {
    uint64_t index = FROM_VIRTUAL_ADDRESS((uint64_t)pointer) / PAGE_SIZE;

    for (size_t i = 0; i < page_count; i++)
        bitmap_unset(bitmap, index + i);

    pmm_info.used_pages -= page_count;
}
