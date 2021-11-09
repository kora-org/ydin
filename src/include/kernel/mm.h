#pragma once

#define HIGHER_HALF_KERNEL_DATA	0xFFFF800000000000UL
#define HIGHER_HALF_KERNEL_CODE	0xFFFFFFFF80000000UL

#define PAGE_SIZE 8192

#define KB_TO_PAGES(kb) (((kb) * 1024) / PAGE_SIZE)
#define ALIGN_DOWN(addr, align) ((addr) & ~((align)-1))
#define ALIGN_UP(addr, align) (((addr) + (align)-1) & ~((align)-1))

#define TO_VIRTUAL_ADDRESS(physical_address) (HIGHER_HALF_KERNEL_DATA + physical_address)
#define TO_PHYSICAL_ADDRESS(physical_address) (HIGHER_HALF_KERNEL_CODE + physical_address)
#define FROM_VIRTUAL_ADDRESS(virtual_address) (virtual_address - HIGHER_HALF_KERNEL_DATA)
#define FROM_PHYSICAL_ADDRESS(physical_address) (physical_address - HIGHER_HALF_KERNEL_CODE)
