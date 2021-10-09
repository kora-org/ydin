#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stivale2.h>
#include <kernel/gdt.h>
#include <kernel/idt.h>
#include <kernel/pic.h>
#include <kernel/pmm.h>
#include <kernel/panic.h>
#include <kernel/kernel.h>

static uint8_t stack[4096];
FILE scr_term;

static struct stivale2_header_tag_terminal terminal_hdr_tag = {
    .tag = {
        .identifier = STIVALE2_HEADER_TAG_TERMINAL_ID,
        .next = 0
    },
    .flags = 0
};

static struct stivale2_header_tag_framebuffer framebuffer_hdr_tag = {
    .tag = {
        .identifier = STIVALE2_HEADER_TAG_FRAMEBUFFER_ID,
        .next = (uint64_t)&terminal_hdr_tag
    },
    .framebuffer_width  = 0,
    .framebuffer_height = 0,
    .framebuffer_bpp    = 0
};

__attribute__((section(".stivale2hdr"), used))
static struct stivale2_header stivale_hdr = {
    .entry_point = 0,
    .stack = (uintptr_t)stack + sizeof(stack),
    .flags = (1 << 1) | (1 << 2),
    .tags = (uintptr_t)&framebuffer_hdr_tag
};

void *stivale2_get_tag(struct stivale2_struct *stivale2_struct, uint64_t id) {
    struct stivale2_tag *current_tag = (void *)stivale2_struct->tags;
    for (;;) {
        if (current_tag == NULL) {
            return NULL;
        }
        if (current_tag->identifier == id) {
            return current_tag;
        }
        current_tag = (void *)current_tag->next;
    }
}

static int _putc(int c, FILE *stream) {
    term_write(&c, 1);
}

void module_load(void (module)(), char* name) {
    printf("[kernel] Initializing %s...", name);
    for (int i = 0; i < (int)term_cols - (strlen("[kernel] Initializing ") + strlen(name) + strlen("...")) - strlen("OK "); i++) {
        printf(" ");
    }
    (module)();
    printf("\033[32mOK\033[0m\n");
}

void halt(void) {
    asm("hlt");
}

void pmm_init_all(void) {
    extern uint8_t *_kernel_start;
    extern uint8_t *_kernel_end;
    pmm_init((uint32_t) &_kernel_end, mem_size_);
    pmm_init_available_regions(&mmap_str_tag->memmap[0], &mmap_str_tag->memmap[mmap_str_tag->entries]);
    //pmm_deinit_kernel();
}

void _start(struct stivale2_struct *stivale2_struct) {
    struct stivale2_struct_tag_terminal *term_str_tag;
    mmap_str_tag = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_MEMMAP_ID);
    term_str_tag = stivale2_get_tag(stivale2_struct, STIVALE2_STRUCT_TAG_TERMINAL_ID);
    if (term_str_tag == NULL) {
        for (;;) {
            asm ("hlt");
        }
    }

    void *term_write_ptr = (void *)term_str_tag->term_write;
    term_write = term_write_ptr;
    term_cols = (uint16_t *)term_str_tag->cols;
    term_rows = (uint16_t *)term_str_tag->rows;
    scr_term.putc = _putc;
    stdin = stdout = &scr_term;

    for (size_t i = 0; i < mmap_str_tag->entries; ++i)
        mem_size_ += mmap_str_tag->memmap[i].length;
    mem_size_ += 1024;

    printf("Welcome to FaruOS!\n");
    printf("Compiled in %s with %s\n", __DATE__, __VERSION__);
    printf("\n");
    printf("Memory size: %d\n", mem_size_);
    module_load(gdt_init, "GDT");
    module_load(idt_init, "IDT");
    module_load(pic_remap, "PIC");
    module_load(pmm_init_all, "PMM");
    printf("Hello World!");
    panic("panic test");

    for (;;) {
        halt();
    }
}
