#include <kernel/io.h>
#include <kernel/pic.h>

void pic_remap(void) {
    outb(0x20, 0x11);
    outb(0xA0, 0x11);

    outb(0x21, 0x20);
    outb(0xA1, 0x28);

    outb(0x21, 0x04);
    outb(0xA1, 0x02);

    outb(0x21, 0x01);
    outb(0xA1, 0x01);

    outb(0x21, 0x0);
    outb(0xA1, 0x0);
}

void pic_eoi(unsigned char irq) {
	if (irq >= 8)
		outb(0xA0, 0x20);
 
	outb(0x20, 0x20);
}

void irq_set_mask(uint8_t irq) {
    uint16_t port;
    uint8_t value;
 
    if(irq < 8) {
        port = 0x21;
    } else {
        port = 0xA1;
        irq -= 8;
    }
    value = inb(port) | (1 << irq);
    outb(port, value);
}
 
void irq_clear_mask(uint8_t irq) {
    uint16_t port;
    uint8_t value;
 
    if(irq < 8) {
        port = 0x21;
    } else {
        port = 0xA1;
        irq -= 8;
    }
    value = inb(port) & ~(1 << irq);
    outb(port, value);
}

static uint16_t __pic_get_irq_reg(int ocw3) {
    outb(0x20, ocw3);
    outb(0xA0, ocw3);
    return (inb(0xA0) << 8) | inb(0x20);
}

uint16_t pic_get_irr(void) {
    return __pic_get_irq_reg(0x0A);
}

uint16_t pic_get_isr(void) {
    return __pic_get_irq_reg(0x0B);
}
