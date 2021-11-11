#include <stdio.h>
#include <string.h>
#include <kernel/pmm.h>
#include <kernel/vmm.h>
#include <kernel/kernel.h>

static uint64_t *root_page_directory;
static uint8_t is_la57_enabled = 0;

static uint8_t check_la57(void) {
    uint64_t cr4;
    asm volatile("mov %%cr4, %0" : "=rax"(cr4));
    return (cr4 >> 12) & 1;
}

void vmm_init(struct stivale2_struct *stivale2_struct) {
    struct stivale2_struct_tag_memmap *memory_map = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_MEMMAP_ID);
    root_page_directory = vmm_create_page_directory();

    if (check_la57()) {
        is_la57_enabled = 1;
        log("5-level paging supported!\n");
    }

    log("Initializing VMM...");
    for (int i = 0; i < term_cols - (strlen("[kernel] Initializing VMM") + strlen("...")) - strlen("OK "); i++) {
        printf(" ");
    }

    // 1/4: map first 4 GiB of memory
    for (uint64_t i = 0; i < 4 * GB; i += PAGE_SIZE)
        vmm_map_page(root_page_directory, i, i, PTE_PRESENT | PTE_READ_WRITE);

    // 2/4: map higher half kernel space
    for (uint64_t i = 0; i < 4 * GB; i += PAGE_SIZE)
        vmm_map_page(root_page_directory, i, TO_VIRTUAL_ADDRESS(i), PTE_PRESENT | PTE_READ_WRITE);

    // 3/4: map protected memory ranges
    for (uint64_t i = 0; i < 0x80000000; i += PAGE_SIZE)
        vmm_map_page(root_page_directory, i, TO_PHYSICAL_ADDRESS(i), PTE_PRESENT | PTE_READ_WRITE);

    // 4/4: map stivale2 structs
    for (uint64_t i = 0; i < memory_map->entries; i++) {
        struct stivale2_mmap_entry *current_entry = &memory_map->memmap[i];

        if (current_entry->type == STIVALE2_MMAP_USABLE) {
            for (uint64_t j = 0; j < memory_map->memmap[i].length; j += PAGE_SIZE)
                vmm_map_page(root_page_directory, TO_VIRTUAL_ADDRESS(j), j, PTE_PRESENT | PTE_READ_WRITE);
        }
    }

    vmm_activate_page_directory(root_page_directory);
    printf("\033[32mOK\033[0m\n");
}

uint64_t *vmm_create_page_directory(void) {
    uint64_t *new_page_directory = pmm_alloc(1);

    memset((void *)FROM_VIRTUAL_ADDRESS((uint64_t)new_page_directory), 0, PAGE_SIZE);
    return new_page_directory;
}

static uint64_t *vmm_get_page_map_level(uint64_t *page_map_level_X, uintptr_t index_X, int flags) {
    if (page_map_level_X[index_X] & 1)
        return (uint64_t *)(page_map_level_X[index_X] & ~(511));
    else {
        page_map_level_X[index_X] = FROM_VIRTUAL_ADDRESS((uint64_t)pmm_alloc(1)) | flags;
        return (uint64_t *)(page_map_level_X[index_X] & ~(511));
    }
}

void vmm_map_page(uint64_t *current_page_directory, uintptr_t physical_address, uintptr_t virtual_address, int flags) {
    if (is_la57_enabled) {
        uintptr_t index5 = (virtual_address & ((uintptr_t)0x1ff << 48)) >> 48;
        uintptr_t index4 = (virtual_address & ((uintptr_t)0x1ff << 39)) >> 39;
        uintptr_t index3 = (virtual_address & ((uintptr_t)0x1ff << 30)) >> 30;
        uintptr_t index2 = (virtual_address & ((uintptr_t)0x1ff << 21)) >> 21;
        uintptr_t index1 = (virtual_address & ((uintptr_t)0x1ff << 12)) >> 12;

        uint64_t *page_map_level5 = current_page_directory;
        uint64_t *page_map_level4 = NULL;
        uint64_t *page_map_level3 = NULL;
        uint64_t *page_map_level2 = NULL;
        uint64_t *page_map_level1 = NULL;

        page_map_level4 = vmm_get_page_map_level(page_map_level5, index5, flags);
        page_map_level3 = vmm_get_page_map_level(page_map_level4, index4, flags);
        page_map_level2 = vmm_get_page_map_level(page_map_level3, index3, flags);
        page_map_level1 = vmm_get_page_map_level(page_map_level2, index2, flags);

        page_map_level1[index1] = physical_address | flags; 
    } else {
        uintptr_t index4 = (virtual_address & ((uintptr_t)0x1ff << 39)) >> 39;
        uintptr_t index3 = (virtual_address & ((uintptr_t)0x1ff << 30)) >> 30;
        uintptr_t index2 = (virtual_address & ((uintptr_t)0x1ff << 21)) >> 21;
        uintptr_t index1 = (virtual_address & ((uintptr_t)0x1ff << 12)) >> 12;

        uint64_t *page_map_level4 = current_page_directory;
        uint64_t *page_map_level3 = NULL;
        uint64_t *page_map_level2 = NULL;
        uint64_t *page_map_level1 = NULL;

        page_map_level3 = vmm_get_page_map_level(page_map_level4, index4, flags);
        page_map_level2 = vmm_get_page_map_level(page_map_level3, index3, flags);
        page_map_level1 = vmm_get_page_map_level(page_map_level2, index2, flags);

        page_map_level1[index1] = physical_address | flags; 
    }

    vmm_flush_tlb((void *)virtual_address);
}

void vmm_flush_tlb(void *address) {
    asm volatile("invlpg (%0)" : : "r" (address));
}

void vmm_activate_page_directory(uint64_t *current_page_directory) {
    asm volatile("mov %0, %%cr3" : : "r" (FROM_VIRTUAL_ADDRESS((uint64_t)current_page_directory)) : "memory");
}
