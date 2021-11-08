#pragma once
#include <stdint.h>
#include <stddef.h>

#define BIT_TO_PAGE(bit)	((size_t)bit * 0x1000)
#define PAGE_TO_BIT(page)	((size_t)page / 0x1000)

typedef struct {
    uint8_t *map;
    size_t size;
} bitmap_t;

void bitmap_set(bitmap_t *bitmap, int bit);
void bitmap_unset(bitmap_t *bitmap, int bit);
uint8_t bitmap_check(bitmap_t *bitmap, int bit);
