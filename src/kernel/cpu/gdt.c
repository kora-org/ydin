#include <stdint.h>
#include <string.h>
#include <kernel/gdt.h>
#include <kernel/kernel.h>

gdt_t gdt = {
    .entries = {
        {0, 0, 0, 0, 0, 0}, // null
        {0xffff, 0, 0, 0x9a, 0xcf, 0}, // kernel code
        {0xffff, 0, 0, 0x92, 0xcf, 0}, // kernel data
        {0xffff, 0, 0, 0xfa, 0xcf, 0}, // user data
        {0xffff, 0, 0, 0xf2, 0xcf, 0}  // user code
    }
};

gdt_pointer_t gdt_pointer;
tss_t tss;

tss_entry_t create_tss_entry(uintptr_t tss);
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
    gdt.tss = create_tss_entry((uintptr_t)&tss);
    memset(&tss, 0, sizeof(tss));

    tss.rsp[0] = (uintptr_t)stack;
    tss.ist[1] = 0;

    tss.iopb_offset = sizeof(tss);

    gdt_pointer.size = sizeof(gdt_t) - 1;
    gdt_pointer.offset = (uint64_t)&gdt;

    gdt_flush(&gdt_pointer);
    tss_flush();
}
