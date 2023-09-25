.global _start
_start:
    mrs x1, mpidr_el1
    and x1, x1, #3
    cbz x1, 2f

1:
    wfe
    b 1b

2:
    ldr x5, =_start
    mov sp, x5

    ldr x5, =bss_start
    ldr w6, =bss_size

3:
    cbz w6, 4f
    str xzr, [x5], #8
    sub w6, w6, #1
    cbnz w6, 3b

4:
    bl kmain
    b 1b
