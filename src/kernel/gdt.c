#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <kernel/gdt.h>

void print_gdt_ent(uint64_t* ent) {
    uint64_t e = *ent;
    uint64_t base = ((e >> 16) & 0xFFFFFF) | ((e >> 32) & 0xFF000000);
    uint64_t limit = (e & 0xFFFF) | ((e >> 32) & 0xF0000);
    uint64_t flags = ((e >> 52) & 0xF);
    uint64_t access = ((e >> 40) & 0xFF);

    uint64_t code = (access & 0x8);

    int bits = (flags&0x2) ? 64 : ((flags&0x4) ? 32 : 16);

    uint64_t length = limit * ((flags & 0x8) ? 4096 : 1);
    printf("%X (%h):  \t", (size_t)base, (size_t)length);
    if(e == 0) {
        puts("NULL");
        return;
    }
    if(access & 0x80) putchar('P');
    printf("%d", (access >> 5) & 0x3);
    if(access & 0x10) putchar('S');
    if(code) printf(" Code%d\t", bits); else puts(" Data\t");
    if(access & 0x4) putchar(code ? 'C' : 'D');
    if(access & 0x2) putchar(code ? 'R' : 'W');
    if(access & 0x1) putchar('A');

    if(flags & 0x8) putchar('G');
    if(flags & 0x1) putchar('z');
}

void print_gdt() {
    struct gdt_ptr pGDT;
    __asm__ __volatile__("sgdt %0" : : "m"(pGDT) : "memory");
    printf("GDT: %x (%d)\n", pGDT.base, pGDT.limit);
    for(int i = 0; i < (pGDT.limit+1)/8; i++) {
        uint64_t *gdt_ent = pGDT.base + 8*i;
        printf("GDT %d: ", i); print_gdt_ent(gdt_ent); putchar('\n');
    }
}
