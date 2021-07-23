#include <kernel/idt.h>

struct idt_entry idt[256];
static unsigned long idt_address;
static unsigned long idt_ptr[2];

void idt_init() {
    idt_address = (unsigned long)idt;
	idt_ptr[0] = (sizeof (struct idt_entry) * 256) + ((idt_address & 0xffff) << 16);
	idt_ptr[1] = idt_address >> 16;

    __asm__ __volatile__(
        "lidt %0\n\t"
        "sti\n\t" : : "m"(idt_ptr)
    );
}

void enable_idt() {
	asm("sti");
}

void disable_idt() {
	asm("cli");
}

void idt_register_handler(uint8_t interrupt, unsigned long address) {
    idt[interrupt].offset_lowerbits = address & 0xffff;
    idt[interrupt].selector = KERNEL_CODE_SEGMENT_OFFSET;
    idt[interrupt].zero = 0;
    idt[interrupt].type_attr = INTERRUPT_GATE;
    idt[interrupt].offset_higherbits = (address & 0xffff0000) >> 16;
}
