#pragma once

void pic_remap(void);
void pic_eoi(uint8_t irq);
void irq_set_mask(uint8_t irq);
void irq_clear_mask(uint8_t irq);
uint16_t pic_get_irr(void);
uint16_t pic_get_isr(void);
