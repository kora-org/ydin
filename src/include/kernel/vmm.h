#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stivale2.h>
#include <kernel/mm.h>

#define GB 0x40000000UL
#define PTE_PRESENT 1
#define PTE_READ_WRITE 2
#define PTE_USER_SUPERVISOR 4
#define PTE_WRITE_THROUGH 8
#define PTE_CHACHE_DISABLED 16
#define PTE_ACCESSED 32
#define PTE_DIRTY 64
#define PTE_PAT 128
#define PTE_GLOBAL 256

void vmm_init(struct stivale2_struct *stivale2_struct);
void vmm_map_page(uint64_t *vmm, uintptr_t physical_address, uintptr_t virtual_address, int flags);
void vmm_flush_tlb(void *address);
void vmm_activate_page_directory(uint64_t *vmm);
