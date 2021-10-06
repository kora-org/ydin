#pragma once
#include <stdint.h>
#include <stddef.h>

uint16_t *term_cols;
uint16_t *term_rows;
void (*term_write)(const char *string, size_t length);
void halt();
