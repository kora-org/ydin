#include <stdio.h>
#include <stdlib.h>
#include <kernel/isr.h>

__attribute__((interrupt)) static void isr0(struct interrupt_frame* frame) {
    panic("division by zero");
    asm("hlt");
}

__attribute__((interrupt)) static void isr1(struct interrupt_frame* frame) {
    panic("debug");
    asm("hlt");
}

__attribute__((interrupt)) static void isr2(struct interrupt_frame* frame) {
    panic("non maskable interrupt");
    asm("hlt");
}

__attribute__((interrupt)) static void isr3(struct interrupt_frame* frame) {
    panic("breakpoint");
    asm("hlt");
}

__attribute__((interrupt)) static void isr4(struct interrupt_frame* frame) {
    panic("into detected overflow");
    asm("hlt");
}

__attribute__((interrupt)) static void isr5(struct interrupt_frame* frame) {
    panic("out of bounds");
    asm("hlt");
}

__attribute__((interrupt)) static void isr6(struct interrupt_frame* frame) {
    panic("invalid opcode");
    asm("hlt");
}

__attribute__((interrupt)) static void isr7(struct interrupt_frame* frame) {
    panic("no coprocessor");
    asm("hlt");
}

__attribute__((interrupt)) static void isr8(struct interrupt_frame* frame) {
    panic("double fault");
    asm("hlt");
}

__attribute__((interrupt)) static void isr9(struct interrupt_frame* frame) {
    panic("coprocessor segment overrun");
    asm("hlt");
}

__attribute__((interrupt)) static void isr10(struct interrupt_frame* frame) {
    panic("bad tss");
    asm("hlt");
}

__attribute__((interrupt)) static void isr11(struct interrupt_frame* frame) {
    panic("segment not present");
    asm("hlt");
}

__attribute__((interrupt)) static void isr12(struct interrupt_frame* frame) {
    panic("stack fault");
    asm("hlt");
}

__attribute__((interrupt)) static void isr13(struct interrupt_frame* frame) {
    panic("general protection fault");

//    panic("heres some info:");

//    panic("ip: ");
//    panic(itoa(frame, ip));
//    panic("sp: ");
//    panic(itoa(frame, sp));
//    panic("cs: ");
//    panic(itoa(frame, cs));

    asm("hlt");
}

__attribute__((interrupt)) static void isr14(struct interrupt_frame* frame) {
    panic("page fault");
    asm("hlt");
}

__attribute__((interrupt)) static void isr15(struct interrupt_frame* frame) {
    panic("unknown interrupt");
    asm("hlt");
}

__attribute__((interrupt)) static void isr16(struct interrupt_frame* frame) {
    panic("coprocessor fault");
    asm("hlt");
}

__attribute__((interrupt)) static void isr17(struct interrupt_frame* frame) {
    panic("alignment check");
    asm("hlt");
}

__attribute__((interrupt)) static void isr18(struct interrupt_frame* frame) {
    panic("machine check");
    asm("hlt");
}

__attribute__((interrupt)) static void isr_reserved(struct interrupt_frame* frame) {
    panic("reserved");
    asm("hlt");
}

void isr_install(void) {
    idt_register_handler(0, (unsigned long)isr0);
    idt_register_handler(1, (unsigned long)isr1);
    idt_register_handler(2, (unsigned long)isr2);
    idt_register_handler(3, (unsigned long)isr3);
    idt_register_handler(4, (unsigned long)isr4);
    idt_register_handler(5, (unsigned long)isr5);
    idt_register_handler(6, (unsigned long)isr6);
    idt_register_handler(7, (unsigned long)isr7);
    idt_register_handler(8, (unsigned long)isr8);
    idt_register_handler(9, (unsigned long)isr9);
    idt_register_handler(10, (unsigned long)isr10);
    idt_register_handler(11, (unsigned long)isr11);
    idt_register_handler(12, (unsigned long)isr12);
    idt_register_handler(13, (unsigned long)isr13);
    idt_register_handler(14, (unsigned long)isr14);
    idt_register_handler(15, (unsigned long)isr15);
    idt_register_handler(16, (unsigned long)isr16);
    idt_register_handler(17, (unsigned long)isr17);
    idt_register_handler(18, (unsigned long)isr18);
    idt_register_handler(19, (unsigned long)isr_reserved);
    idt_register_handler(20, (unsigned long)isr_reserved);
    idt_register_handler(21, (unsigned long)isr_reserved);
    idt_register_handler(22, (unsigned long)isr_reserved);
    idt_register_handler(23, (unsigned long)isr_reserved);
    idt_register_handler(24, (unsigned long)isr_reserved);
    idt_register_handler(25, (unsigned long)isr_reserved);
    idt_register_handler(26, (unsigned long)isr_reserved);
    idt_register_handler(27, (unsigned long)isr_reserved);
    idt_register_handler(28, (unsigned long)isr_reserved);
    idt_register_handler(29, (unsigned long)isr_reserved);
    idt_register_handler(30, (unsigned long)isr_reserved);
    idt_register_handler(31, (unsigned long)isr_reserved);

    idt_init();
}
