#include <stdint.h>
#include <stddef.h>
#include <kernel/bitmap.h>

void bitmap_set(bitmap_t *bitmap, int bit) {
    bitmap->map[bit / 32] |= (1 << (bit % 32));
}

void bitmap_unset(bitmap_t *bitmap, int bit) {
    bitmap->map[bit / 32] &= ~(1 << (bit % 32));
}

uint8_t bitmap_check(bitmap_t *bitmap, int bit) {
	return bitmap->map[bit / 8] & (1 << (bit % 8));
}
