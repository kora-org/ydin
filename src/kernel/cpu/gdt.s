[bits 64]
global gdt_flush
gdt_flush:
    lgdt [rdi]
    mov ax, 0x10
    mov ss, ax
    mov ds, ax
    mov es, ax
    pop rdi
    mov rax, 0x8
    push rax
    push rdi
    retfq

global tss_flush
tss_flush:
    mov ax, 0x28
    ltr ax
    ret
