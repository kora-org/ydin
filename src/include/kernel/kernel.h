#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stivale2.h>

static uint16_t *term_cols;
static uint16_t *term_rows;
void (*term_write)(const char *string, size_t length);
static struct stivale2_struct *boot_struct;
void *stivale2_get_tag(struct stivale2_struct *stivale2_struct, uint64_t id);
void halt(void);
