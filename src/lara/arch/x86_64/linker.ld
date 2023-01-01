ENTRY(_start)

PHDRS {
    null PT_NULL FLAGS(0);
    text PT_LOAD FLAGS((1 << 0) | (1 << 2));
    rodata PT_LOAD FLAGS((1 << 2));
    data PT_LOAD FLAGS((1 << 1) | (1 << 2));
}

SECTIONS {
    . = 0xffffffff80000000;

    text_start = .;

    .text : {
        *(.text .text.*)
    } :text

    text_end = .;

    . += CONSTANT(MAXPAGESIZE);

    rodata_start = .;

    .rodata : {
        *(.rodata .rodata.*)
    } :rodata

    rodata_end = .;

    . += CONSTANT(MAXPAGESIZE);

    data_start = .;

    .data : {
        *(.data .data.*)
    } :data

    .bss : {
        *(COMMON)
        *(.bss .bss.*)
    } :data

    data_end = .;
}
