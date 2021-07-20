/* Tell the linker that we want the symbol _start to be our entry point */
ENTRY(_start)
 
/* Define the program headers we want so the bootloader gives us the right */
/* MMU permissions */
PHDRS
{
    null    PT_NULL    FLAGS(0) ;                   /* Null segment */
    rodata  PT_LOAD    FLAGS((1 << 2)) ;            /* Read only */
    text    PT_LOAD    FLAGS((1 << 0) | (1 << 2)) ; /* Execute + Read */
    data    PT_LOAD    FLAGS((1 << 1) | (1 << 2)) ; /* Write + Read */
    dynamic PT_DYNAMIC FLAGS((1 << 1) | (1 << 2)) ; /* Dynamic segment needed for PIE */
}
 
SECTIONS
{
    /* We wanna be placed in the higher half, 2MiB above 0 in physical memory. */
    /* Since we are going to use PIE, this is just the base load address, but the */
    /* bootloader will be able to relocate us as it sees fit. */
    . = 0xffffffff80200000;
 
    /* We place the .stivale2hdr section containing the header in its own section, */
    /* and we use the KEEP directive on it to make sure it doesn't get discarded. */
    .stivale2hdr ALIGN(4K) : {
        KEEP(*(.stivale2hdr))
    } :rodata
 
    /* Then let's place all the other traditional executable sections afterwards. */
    .rodata ALIGN(4K) : {
        *(.rodata*)
    } :rodata
 
    .text ALIGN(4K) : {
        *(.text*)
    } :text
 
    .data ALIGN(4K) : {
        *(.data*)
    } :data
 
    /* Dynamic section needed for PIE */
    .dynamic ALIGN(4K) : {
        *(.dynamic)
    } :data :dynamic
 
    .bss ALIGN(4K) : {
        *(COMMON)
        *(.bss*)
    } :data
}
