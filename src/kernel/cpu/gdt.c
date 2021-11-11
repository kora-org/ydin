#include <stdint.h>
#include <string.h>
#include <kernel/gdt.h>
#include <kernel/kernel.h>

tss_entry_t create_tss_entry(uintptr_t tss);

gdt_desc_t gdt_desc;
tss_t tss;

gdt_t gdt = {
    {0, 0, 0, 0x00, 0x00, 0},
    {0xffff, 0, 0, 0x9a, (1 << 5) | (1 << 7) | 0x0F, 0},
    {0xffff, 0, 0, 0x92, (1 << 5) | (1 << 7) | 0x0F, 0},
    {0xffff, 0, 0, 0xfa, (1 << 5) | (1 << 7) | 0x0F, 0},
    {0xffff, 0, 0, 0xf2, (1 << 5) | (1 << 7) | 0x0F, 0},
    {0x67, 0, 0x00, 0xe9, 0, 0}
};

tss_entry_t create_tss_entry(uintptr_t tss) {
    return (tss_entry_t){
        .length = sizeof(tss_entry_t),
        .base_low16 = tss & 0xffff,
        .base_mid8 = (tss >> 16) & 0xff,
        .flags1 = 0x89,
        .flags2 = 0,
        .base_high8 = (tss >> 24) & 0xff,
        .base_upper32 = tss >> 32,
        .reserved = 0,
    };
}

void gdt_init(void) {
    gdt_desc.size = sizeof(gdt_t) - 1;
    gdt_desc.offset = (uint64_t)&gdt;

    gdt.tss = create_tss_entry((uintptr_t)&tss);
    memset(&tss, 0, sizeof(tss));

    tss.rsp[0] = (uintptr_t)stack;
    tss.ist[1] = 0;

    tss.iopb_offset = sizeof(tss);

    gdt_flush(&gdt_desc);
    tss_flush();
}
