#pragma once
#include <stdint.h>

typedef struct {
    uint16_t isr_low;
    uint16_t kernel_cs;
    uint8_t	ist;
	uint8_t attributes;
	uint16_t isr_mid;
	uint32_t isr_high;
	uint32_t reserved;
} __attribute__((packed)) idt_entry_t;

typedef struct {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed)) idtr_t;

void idt_set_descriptor(uint8_t vector, void* isr, uint8_t flags);
void idt_init(void);
