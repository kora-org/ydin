#pragma once
#include <stdint.h>

#define is_aligned(addr, align) !((addr) & ~((align) - 1))
#define align(addr, align) (((addr) & ~((align) - 1)) + (align))
#define kb2blocks(x) (((x) * 1024) / 4096)

static size_t mem_size;
static uint32_t used_blocks;
static uint32_t max_blocks;
static uint32_t *pmmap;
static size_t pmmap_size;

void pmm_init(uint32_t pmmap_addr, size_t size);
void pmm_init_region(uint32_t base, size_t size);
void pmm_deinit_region(uint32_t base, size_t size);
void pmm_init_available_regions(struct stivale2_mmap_entry *mmap, struct stivale2_mmap_entry *mmap_end);
void pmm_deinit_kernel(void);
void *pmm_alloc_block(void);
void pmm_free_block(void *p);
