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
#include <kernel/panic.h>
#include <kernel/kernel.h>
#include <kernel/isr.h>

void isr_handler(uint64_t irq, exception_t *rsp) {
    isr_panic(rsp, "Exception occurred");
}

EXCEPTION(0)
EXCEPTION(1)
EXCEPTION(2)
EXCEPTION(3)
EXCEPTION(4)
EXCEPTION(5)
EXCEPTION(6)
EXCEPTION(7)
EXCEPTION(8)
EXCEPTION(9)
EXCEPTION(10)
EXCEPTION(11)
EXCEPTION(12)
EXCEPTION(13)
EXCEPTION(14)
EXCEPTION(15)
EXCEPTION(16)
EXCEPTION(17)
EXCEPTION(18)
EXCEPTION(19)
EXCEPTION(20)
EXCEPTION(30)
void isr_reserved(void) {}
