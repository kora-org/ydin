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

#include <kernel/symbols.h>

sym_table_t symbol_table[] = {
    {0xffffffff80000d60, "__panic_log"},
    {0xffffffff80003010, "vmm_get_next_level"},
    {0xffffffff80005c90, "_out_char"},
    {0xffffffff80004920, "_vsnprintf"},
    {0xffffffff80005ff0, "_out_null"},
    {0xffffffff80006000, "_atoi"},
    {0xffffffff800060d0, "_ntoa_format"},
    {0xffffffff80005d50, "_out_buffer"},
    {0xffffffff80005f40, "_out_fct"},
    {0xffffffff80000000, "stivale2_get_tag"},
    {0xffffffff80000fb0, "__ubsan_handle_type_mismatch_v1"},
    {0xffffffff800000f0, "__log"},
    {0xffffffff80004870, "printf"},
    {0xffffffff80005e50, "vprintf"},
    {0xffffffff80000190, "halt"},
    {0xffffffff800001a0, "_start"},
    {0xffffffff80001250, "gdt_init"},
    {0xffffffff80003300, "idt_init"},
    {0xffffffff80001750, "pmm_init"},
    {0xffffffff800027c0, "vmm_init"},
    {0xffffffff80003850, "pic_remap"},
    {0xffffffff80000420, "__panic"},
    {0xffffffff800003b0, "outb"},
    {0xffffffff800003c0, "inb"},
    {0xffffffff800003d0, "outw"},
    {0xffffffff800003e0, "inw"},
    {0xffffffff800003f0, "outl"},
    {0xffffffff80000400, "inl"},
    {0xffffffff80000410, "io_wait"},
    {0xffffffff80000f80, "__ubsan_handle_out_of_bounds"},
    {0xffffffff80000ef0, "__ubsan_handle_pointer_overflow"},
    {0xffffffff80000e00, "__ubsan_handle_add_overflow"},
    {0xffffffff80000e30, "__ubsan_handle_sub_overflow"},
    {0xffffffff80000e60, "__ubsan_handle_mul_overflow"},
    {0xffffffff80000e90, "__ubsan_handle_divrem_overflow"},
    {0xffffffff80000ec0, "__ubsan_handle_negate_overflow"},
    {0xffffffff80000f20, "__ubsan_handle_shift_out_of_bounds"},
    {0xffffffff80000f50, "__ubsan_handle_load_invalid_value"},
    {0xffffffff80000fc0, "__ubsan_handle_vla_bound_not_positive"},
    {0xffffffff80000ff0, "__ubsan_handle_nonnull_return"},
    {0xffffffff80001020, "__ubsan_handle_nonnull_arg"},
    {0xffffffff80001050, "__ubsan_handle_builtin_unreachable"},
    {0xffffffff80001080, "__ubsan_handle_invalid_builtin"},
    {0xffffffff800010b0, "symbols_get_function_name"},
    {0xffffffff80003f40, "memset"},
    {0xffffffff80001360, "tss_init"},
    {0xffffffff80001410, "tss_set_stack"},
    {0xffffffff80001420, "bitmap_set"},
    {0xffffffff80001530, "bitmap_unset"},
    {0xffffffff80001650, "bitmap_check"},
    {0xffffffff80002550, "mmap_get_entry_type"},
    {0xffffffff800025e0, "pmm_free"},
    {0xffffffff80002630, "pmm_alloc"},
    {0xffffffff80002790, "pmm_alloc_zero"},
    {0xffffffff80002e20, "vmm_map_page"},
    {0xffffffff80002e10, "vmm_create_page_directory"},
    {0xffffffff80003000, "vmm_activate_page_directory"},
    {0xffffffff80003180, "vmm_flush_tlb"},
    {0xffffffff80003190, "idt_set_descriptor"},
    {0xffffffff80003420, "isr_0"},
    {0xffffffff80003450, "isr_1"},
    {0xffffffff80003480, "isr_2"},
    {0xffffffff800034b0, "isr_3"},
    {0xffffffff800034e0, "isr_4"},
    {0xffffffff80003510, "isr_5"},
    {0xffffffff80003540, "isr_6"},
    {0xffffffff80003570, "isr_7"},
    {0xffffffff800035a0, "isr_8"},
    {0xffffffff800035d0, "isr_9"},
    {0xffffffff80003600, "isr_10"},
    {0xffffffff80003630, "isr_11"},
    {0xffffffff80003660, "isr_12"},
    {0xffffffff80003690, "isr_13"},
    {0xffffffff800036c0, "isr_14"},
    {0xffffffff80003840, "isr_reserved"},
    {0xffffffff80003720, "isr_16"},
    {0xffffffff80003750, "isr_17"},
    {0xffffffff80003780, "isr_18"},
    {0xffffffff800037b0, "isr_19"},
    {0xffffffff800037e0, "isr_20"},
    {0xffffffff80003810, "isr_30"},
    {0xffffffff800033f0, "isr_handler"},
    {0xffffffff800036f0, "isr_15"},
    {0xffffffff80003920, "pic_eoi"},
    {0xffffffff80003950, "irq_set_mask"},
    {0xffffffff800039c0, "irq_clear_mask"},
    {0xffffffff80003a30, "pic_get_irr"},
    {0xffffffff80003a80, "pic_get_isr"},
    {0xffffffff80003b00, "memchr"},
    {0xffffffff80003b80, "memcmp"},
    {0xffffffff80003d40, "memcpy"},
    {0xffffffff80003d50, "memmove"},
    {0xffffffff80003f50, "strchr"},
    {0xffffffff80003fd0, "strcpy"},
    {0xffffffff80004110, "strncpy"},
    {0xffffffff800042c0, "strlen"},
    {0xffffffff80004330, "strcmp"},
    {0xffffffff80004440, "strncmp"},
    {0xffffffff800045a0, "strspn"},
    {0xffffffff800046c0, "strcspn"},
    {0xffffffff800047d0, "strtok"},
    {0xffffffff80006880, "putc"},
    {0xffffffff800068b0, "putchar"},
    {0xffffffff800068e0, "puts"},
    {0xffffffff80005cb0, "sprintf"},
    {0xffffffff80005dc0, "snprintf"},
    {0xffffffff80005e80, "vsnprintf"},
    {0xFFFFFFFF, ""}
};

static sym_table_t lookup(uint64_t address) {
    size_t i;
    for (i = 0; symbol_table[i].address != 0xffffffff; i++)
        if ((symbol_table[i].address << 52) == (address << 52))
            return symbol_table[i];
    return symbol_table[i];
}

const char *symbols_get_function_name(uint64_t address) {
    sym_table_t table = lookup(address);
    if (table.address == 0xffffffff)
        return "unknown";
    return table.function_name;
}
