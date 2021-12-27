#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <kernel/io.h>
#include <kernel/idt.h>
#include <kernel/isr.h>
#include <kernel/pic.h>
#include <kernel/kernel.h>

static idt_entry_t idt[256];
static idtr_t idtr;
static bool vectors[256];

void* isr_table[32] = {
    isr_0,
    isr_1,
    isr_2,
    isr_3,
    isr_4,
    isr_5,
    isr_6,
    isr_7,
    isr_8,
    isr_9,
    isr_10,
    isr_11,
    isr_12,
    isr_13,
    isr_14,
    isr_reserved,
    isr_16,
    isr_17,
    isr_18,
    isr_19,
    isr_20,
    isr_reserved,
    isr_reserved,
    isr_reserved,
    isr_reserved,
    isr_reserved,
    isr_reserved,
    isr_reserved,
    isr_reserved,
    isr_reserved,
    isr_30,
    pic_remap
};

void idt_set_descriptor(uint8_t vector, void* isr, uint8_t flags) {
    idt[vector].base_low = (uint64_t)isr & 0xFFFF;
    idt[vector].cs = 0x28;
    idt[vector].ist = 0;
    idt[vector].attributes = flags;
    idt[vector].base_mid = ((uint64_t)isr >> 16) & 0xFFFF;
    idt[vector].base_high = ((uint64_t)isr >> 32) & 0xFFFFFFFF;
    idt[vector].rsv0 = 0;
}

void idt_init() {
    log("Initializing IDT...\n");
    idtr.base = (uintptr_t)&idt[0];
    idtr.limit = (uint16_t)sizeof(idt_entry_t) * 256 - 1;
 
    for (uint8_t vector = 0; vector < 32; vector++) {
        idt_set_descriptor(vector, isr_table[vector], 0x8E);
        vectors[vector] = true;
    }

    for (uint8_t vector = 0; vector > 31; vector++) {
        idt_set_descriptor(vector, &pic_eoi, 0x8E);
        vectors[vector] = true;
        if (vector == 48)
            break;
    }
 
    asm volatile ("lidt %0" : : "m"(idtr));
    enable_interrupts();
    log("IDT initialized!\n");
}
