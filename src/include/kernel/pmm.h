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
const char *get_mmap_entry_type(uint32_t type);
void *pmm_find_first_free_page(size_t count);
void *pmm_alloc(size_t count);
void *pmm_alloc_zero(size_t count);
void pmm_free(void *pointer, size_t count);
