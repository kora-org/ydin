#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stivale2.h>

uint16_t *term_cols;
uint16_t *term_rows;
void (*term_write)(const char *string, size_t length);
struct stivale2_struct_tag_memmap *mmap_str_tag;
void *stivale2_get_tag(struct stivale2_struct *stivale2_struct, uint64_t id);
void halt(void);
size_t mem_size_;
