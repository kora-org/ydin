/*
 * Copyright © 2021 Leap of Azzam
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

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <kernel/kernel.h>
#include <kernel/idt.h>
#include <kernel/isr.h>
#include <kernel/panic.h>
#include <kernel/symbols.h>

static void __panic_log(const char *file, int line, const char *str, ...) {
    va_list args;
    va_start(args, str);
    printf("[%s:%d] ", file, line);
    vprintf(str, args);
    va_end(args);
}

#define panic_log(str...) __panic_log(file, line, str);

void __panic(char *file, int line, int is_isr, exception_t *exception, char *message, ...) {
    va_list args;
    va_start(args, message);

    static bool is_panic;
    if (!is_panic) {
        is_panic = true;
    } else {
        panic_log("Yo dawg, I heard you like kernel panic. So I put a kernel panic in\n");
        panic_log("your kernel panic so you can panic while you panic!\n");
        panic_log("");
    }

    uintptr_t *rip = __builtin_return_address(0);
    uintptr_t *rbp = __builtin_frame_address(0);

    printf("\n");

    if (is_isr == 0) {
        panic_log("Kernel panic: ");
        vprintf(message, args);
        printf("\n");
    } else {
        panic_log("Kernel panic: Exception occured\n");
    }

    va_end(args);
    if (is_isr == 0) {
        panic_log("In file %s at line %d \n", file, line);
        panic_log("rip: 0x%p\n", rip);
        panic_log("rbp: 0x%p\n", rbp);
        panic_log("Stacktrace:\n");
        for (;;) {
            size_t old_rbp = rbp[0];
            size_t ret_address = rbp[0];
            if (!ret_address)
                break;

            panic_log("\t0x%.16llX\t%s\n", ret_address, symbols_get_function_name(ret_address));

            if (!old_rbp)
                break;
            rbp = (void *)old_rbp;
        }
        panic_log("\n");
    } else {
        panic_log("Exception: %s\n", exceptions[exception->isr_number]);
        panic_log("Error code: 0x%.16llX\n", exception->error_code);
        panic_log("Register dump:\n");
        panic_log("\trax: 0x%.16llX, rbx:    0x%.16llX, rcx: 0x%.16llX, rdx: 0x%.16llX\n",
                     exception->rax, exception->rbx,    exception->rcx, exception->rdx);
        panic_log("\trsi: 0x%.16llX, rdi:    0x%.16llX, rbp: 0x%.16llX, r8 : 0x%.16llX\n",
                     exception->rsi, exception->rdi,    exception->rbp, exception->r8);
        panic_log("\tr9:  0x%.16llX, r10:    0x%.16llX, r11: 0x%.16llX, r12: 0x%.16llX\n",
                     exception->r9,  exception->r10,    exception->r11, exception->r12);
        panic_log("\tr13: 0x%.16llX, r14:    0x%.16llX, r15: 0x%.16llX, ss : 0x%.16llX\n",
                     exception->r13, exception->r14,    exception->r15, exception->ss);
        panic_log("\trsp: 0x%.16llX, rflags: 0x%.16llX, cs : 0x%.16llX, rip: 0x%.16llX\n",
                     exception->rsp, exception->rflags, exception->cs,  exception->rip);

    }
    panic_log("System halted");
    disable_interrupts();
    for (;;) {
        halt();
    }
}
