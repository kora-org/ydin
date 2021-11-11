#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stivale2.h>

extern int term_cols;
extern int term_rows;
void (*term_write)(const char *string, size_t length);
extern struct stivale2_struct *boot_struct;
extern struct stivale2_struct_tag_kernel_base_address *kernel_base;
void *stivale2_get_tag(struct stivale2_struct *stivale2_struct, uint64_t id);
void halt(void);
void log(const char *str, ...);

#define PHYSICAL_ADDRESS kernel_base->physical_base_address
#define VIRTUAL_ADDRESS kernel_base->virtual_base_address
