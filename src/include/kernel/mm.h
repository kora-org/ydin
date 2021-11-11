#pragma once

#define PHYSICAL_MEMORY_OFFSET ((uintptr_t)0xFFFF800000000000)
#define KERNEL_BASE ((uintptr_t)0xFFFFFFFF80000000)

#define PAGE_SIZE 8192

#define BIT_TO_PAGE(bit) ((size_t)bit * 0x1000)
#define PAGE_TO_BIT(page) ((size_t)page / 0x1000)

#define KB_TO_PAGES(kb) (((kb) * 1024) / PAGE_SIZE)
#define ALIGN_DOWN(addr, align) ((addr) & ~((align)-1))
#define ALIGN_UP(addr, align) (((addr) + (align)-1) & ~((align)-1))

#define TO_VIRTUAL_ADDRESS(physical_address) (PHYSICAL_MEMORY_OFFSET + physical_address)
#define TO_PHYSICAL_ADDRESS(physical_address) (KERNEL_BASE + physical_address)
#define FROM_VIRTUAL_ADDRESS(virtual_address) (virtual_address - PHYSICAL_MEMORY_OFFSET)
#define FROM_PHYSICAL_ADDRESS(physical_address) (physical_address - KERNEL_BASE)
