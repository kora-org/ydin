#pragma once
#include <kernel/kernel.h>

#define KERNEL_DATA_OFFSET (0xffff800000000000UL)
#define KERNEL_CODE_OFFSET (0xffffffff80000000UL)

#define KB_TO_PAGES(kb) (((kb) * 1024) / PAGE_SIZE)
#define ALIGN_DOWN(addr, align) ((addr) & ~((align)-1))
#define ALIGN_UP(addr, align) (((addr) + (align)-1) & ~((align)-1))
