#include <stdint.h>
#include <string.h>
#include <kernel/gdt.h>
#include <kernel/kernel.h>

gdt_t gdt = {
    {0, 0, 0, 0, 0, 0}, // null
    {0xffff, 0, 0, 0x9a, 0x80, 0}, // 16-bit code
    {0xffff, 0, 0, 0x92, 0x80, 0}, // 16-bit data
    {0xffff, 0, 0, 0x9a, 0xcf, 0}, // 32-bit code
    {0xffff, 0, 0, 0x92, 0xcf, 0}, // 32-bit data
    {0, 0, 0, 0x9a, 0xa2, 0}, // 64-bit code
    {0, 0, 0, 0x92, 0xa0, 0}, // 64-bit data
    {0, 0, 0, 0xF2, 0, 0}, // user data
    {0, 0, 0, 0xFA, 0x20, 0}, // user code
    {0x68, 0, 0, 0x89, 0x20, 0, 0, 0} // tss
};

gdt_pointer_t gdt_pointer;
tss_t tss;

void gdt_init(void) {
    log("Initializing GDT...\n");
    tss_init();

    gdt_pointer.size = sizeof(gdt_t) - 1;
    gdt_pointer.offset = (uint64_t)&gdt;

    gdt_flush(&gdt_pointer);
    tss_flush();
    log("GDT initialized!\n");
}

void tss_init(void) {
    memset(&tss, 0, sizeof(tss));

    tss.rsp[0] = (uintptr_t)stack;
    tss.ist[1] = 0;

    tss.iopb_offset = sizeof(tss);

    gdt.tss.base_low16 = (uintptr_t)&tss & 0xFFFF;
    gdt.tss.base_mid8 = ((uintptr_t)&tss >> 16) & 0xFF;
    gdt.tss.base_high8 = ((uintptr_t)&tss >> 24) & 0xFF;
    gdt.tss.base_upper32 = (uintptr_t)&tss >> 32;
}

void tss_set_stack(uintptr_t stack) {
    tss.rsp[0] = stack;
}
