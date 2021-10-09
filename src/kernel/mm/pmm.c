#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stivale2.h>
#include <kernel/pmm.h>
#include <kernel/bitmap.h>
#include <kernel/kernel.h>

void pmm_init(uint32_t pmmap_addr, size_t size) {
    mem_size    = size;
    max_blocks  = kb2blocks(mem_size);
    used_blocks = max_blocks;
    pmmap       = (uint32_t *) pmmap_addr;

    pmmap_size = max_blocks / 32;
    if (max_blocks % 32)
        pmmap_size++;

    memset(pmmap, 0xFF, pmmap_size);
}

void pmm_init_region(uint32_t base, size_t size) {
    size_t blocks  = size / 4096;
    uint32_t align = base / 4096;

    for (size_t i = 0; i < blocks; i++) {
        bitmap_unset(pmmap, align++);
        used_blocks--;
    }

    bitmap_set(pmmap, 0);
}

void pmm_deinit_region(uint32_t base, size_t size) {
    size_t blocks = size / 4096;
    uint32_t align = base / 4096;

    for (size_t i = 0; i < blocks; i++) {
        bitmap_set(pmmap, align++);
        used_blocks++;
    }
}

void pmm_init_available_regions(uint32_t mmap_, uint32_t mmap_end_) {
    struct stivale2_mmap_entry *mmap = (struct stivale2_mmap_entry *) mmap_;
    struct stivale2_mmap_entry *mmap_end = (struct stivale2_mmap_entry *) mmap_end_;

    for (int i = 0; mmap < mmap_end; mmap++, i++)
        if (mmap->type == STIVALE2_MMAP_USABLE)
            pmm_init_region((uint32_t) mmap->base, (size_t) mmap->length);
}

void pmm_deinit_kernel(void) {
    extern uint8_t *_kernel_start;
    extern uint8_t *_kernel_end;

    size_t kernel_size = (size_t) &_kernel_end - (size_t) &_kernel_start;

    uint32_t pmmap_size_aligned = pmmap_size;
    if (!is_aligned(pmmap_size_aligned, 4096))
        pmmap_size_aligned = align(pmmap_size_aligned, 4096);

    pmm_deinit_region((uint32_t) &_kernel_start, kernel_size);
    pmm_deinit_region((uint32_t) &_kernel_end, pmmap_size_aligned);
}

void *pmm_alloc_block(void) {
    if (used_blocks - max_blocks <= 0)
        return NULL;

    int p_index = bitmap_first_unset(pmmap, max_blocks);

    if (p_index == -1)
        return NULL;

    bitmap_set(pmmap, p_index);
    used_blocks++;

    return (void *) (512 * p_index);
}

void pmm_free_block(void *p) {
    if (p == NULL)
        return;

    uint32_t p_addr = (uint32_t) p;

    int index = p_addr / 4096;
    bitmap_unset(pmmap, index);

    used_blocks--;
}
