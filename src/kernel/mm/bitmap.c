#include <stdint.h>
#include <stddef.h>
#include <kernel/bitmap.h>

void bitmap_set(uint32_t *bitmap, int bit) {
    bitmap[bit / 32] |= (1 << (bit % 32));
}

void bitmap_unset(uint32_t *bitmap, int bit) {
    bitmap[bit / 32] &= ~(1 << (bit % 32));
}

int bitmap_first_unset(uint32_t *bitmap, size_t size) {
    uint32_t rem_bits = size % 32;

    for (uint32_t i = 0; i < size / 32; i++)
        if (bitmap[i] != 0XFFFFFFFF)
            for (int j = 0; j < 32; j++)
                if (!(bitmap[i] & (1 << j)))
                    return (i * 32) + j;

    if (rem_bits) {
        for (uint32_t j = 0; j < rem_bits; j++)
            if (!(bitmap[size / 32] & (1 << j)))
                return ((size / 32) * 32) + j;
    }

    return -1;
}
