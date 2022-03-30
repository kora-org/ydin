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
#include <stdint.h>
#include <stddef.h>
#include <stdarg.h>

typedef struct _FILE {
    uint8_t _can_read, _can_write;

    uint64_t (*seek)(int mode, uint64_t offset);
    int64_t (*read)(void *arg, void *buffer, uint64_t offset, uint64_t max_count);
    int64_t (*write)(void *arg, const void *buffer, uint64_t offset, uint64_t max_count);
    void (*close)(void *arg);
} FILE;

//FILE *stdin;
//FILE *stdout;
//FILE *stderr;

int putc(const char c);
int putchar(char c);
int puts(const char *str);
int printf(const char *format, ...) ;
int sprintf(char *buffer, const char *format, ...);
int vsprintf(char *buffer, const char *format, va_list va);
int snprintf(char *buffer, size_t count, const char *format, ...) ;
int vsnprintf(char *buffer, size_t count, const char *format, va_list va);
int vprintf(const char *format, va_list va);
int fctprintf(void (*out)(char character, void *arg), void *arg, const char *format, ...);
int vfctprintf(void (*out)(char character, void *arg), void *arg, const char *format, va_list va);
