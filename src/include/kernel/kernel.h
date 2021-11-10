#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stivale2.h>

extern int term_cols;
extern int term_rows;
void (*term_write)(const char *string, size_t length);
static struct stivale2_struct *boot_struct;
void *stivale2_get_tag(struct stivale2_struct *stivale2_struct, uint64_t id);
void halt(void);
void log(const char *str, ...);
