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

#pragma once

typedef signed char koete_i8_t;
typedef unsigned char koete_u8_t;
typedef short koete_i16_t;
typedef unsigned short koete_u16_t;
typedef int koete_i32_t;
typedef unsigned int koete_u32_t;
typedef long koete_i64_t;
typedef unsigned long koete_u64_t;
typedef long long koete_i128_t;
typedef unsigned long long koete_u128_t;
typedef float koete_f32_t;
typedef double koete_f64_t;

typedef char koete_char_t;
typedef koete_i8_t koete_sbyte_t;
typedef koete_u8_t koete_byte_t;
typedef koete_i16_t koete_short_t;
typedef koete_u16_t koete_ushort_t;
typedef koete_i32_t koete_int_t;
typedef koete_u32_t koete_uint_t;
typedef koete_i64_t koete_long_t;
typedef koete_u64_t koete_ulong_t;
typedef koete_i128_t koete_ilonglong_t;
typedef koete_u128_t koete_ulonglong_t;
typedef koete_f32_t koete_float_t;
typedef koete_f64_t koete_double_t;

typedef koete_int_t koete_bool_t;
typedef koete_char_t *koete_string_t;

#define koete_bool_true 1
#define koete_bool_false 0
