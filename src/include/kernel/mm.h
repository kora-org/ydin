#pragma once
#include <kernel/kernel.h>

#define PHYSICAL_OFFSET ((uintptr_t)0xffff800000000000)

#define KB_TO_PAGES(kb) (((kb) * 1024) / PAGE_SIZE)
#define ALIGN_DOWN(addr, align) ((addr) & ~((align)-1))
#define ALIGN_UP(addr, align) (((addr) + (align)-1) & ~((align)-1))
