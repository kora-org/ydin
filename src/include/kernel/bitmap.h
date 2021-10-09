#pragma once
#include <stdint.h>
#include <stddef.h>

void bitmap_set(uint32_t *bitmap, int bit);
void bitmap_unset(uint32_t *bitmap, int bit);
int bitmap_first_unset(uint32_t *bitmap, size_t size);
