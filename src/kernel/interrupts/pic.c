/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Copyright © 2022 Leap of Azzam
 *
 * This file is part of FaruOS.
 *
 * FaruOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FaruOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FaruOS.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <kernel/io.h>
#include <kernel/pic.h>

void pic_remap(void) {
    uint8_t mask1 = inb(0x21);
    uint8_t mask2 = inb(0xA1);
    outb(0x20, 0x11);
    outb(0xA0, 0x11);
    io_wait();
    outb(0x21, 0x20);
    outb(0xA1, 0x28);
    io_wait();
    outb(0x21, 0x04);
    outb(0xA1, 0x02);
    io_wait();
    outb(0x21, 0x01);
    outb(0xA1, 0x01);
    io_wait();
    outb(0x21, mask1);
    outb(0xA1, mask2);
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
