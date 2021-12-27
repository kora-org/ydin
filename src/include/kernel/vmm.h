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
uint64_t *vmm_create_page_directory(void);
void vmm_map_page(uint64_t *vmm, uintptr_t physical_address, uintptr_t virtual_address, int flags);
void vmm_flush_tlb(uintptr_t address);
void vmm_activate_page_directory(uint64_t *vmm);
