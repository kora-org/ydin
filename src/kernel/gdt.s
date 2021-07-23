section .rodata
align 8
gdt64:
    dq 0
.codesys: equ $-gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
.datasys: equ $-gdt64
    dq (1<<44) | (1<<47) | (1<<41)
.codeusr: equ $-gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53) | (3<<45)
.datausr: equ $-gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (3<<45)
.pointer:
    dw .pointer - gdt64 - 1
    dq gdt64

section .text
global load_gdt
load_gdt:
    lgdt [gdt64.pointer]
    ; now what I tried unsuccessfully:

    mov rax, gdt64.codesys;
    push rax
    mov rax, load_gdt_done
    push rax   ; function to execute next
    retfq               ; far return (pops address and code segment)
load_gdt_done:
    mov ax, gdt64.datasys
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ret
