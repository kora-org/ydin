/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Copyright © 2022 Leap of Azzam
 *
 * This file is part of FaruOS.
 *
 * FaruOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FaruOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FaruOS.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <kernel/bitmap.h>

void bitmap_set(bitmap_t *bitmap, int bit) {
    bitmap->map[bit / 8] |= (1 << (bit % 8));
}

void bitmap_unset(bitmap_t *bitmap, int bit) {
    bitmap->map[bit / 8] &= ~(1 << (bit % 8));
}

uint8_t bitmap_check(bitmap_t *bitmap, int bit) {
    return bitmap->map[bit / 8] & (1 << (bit % 8));
}
