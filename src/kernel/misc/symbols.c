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
    {0xffffffff80000ef0, "__panic_log"},
    {0xffffffff800031a0, "vmm_get_next_level"},
    {0xffffffff80005e20, "_out_char"},
    {0xffffffff80004ab0, "_vsnprintf"},
    {0xffffffff80006180, "_out_null"},
    {0xffffffff80006190, "_atoi"},
    {0xffffffff80006260, "_ntoa_format"},
    {0xffffffff80005ee0, "_out_buffer"},
    {0xffffffff800060d0, "_out_fct"},
    {0xffffffff80000000, "stivale2_get_tag"},
    {0xffffffff80001140, "__ubsan_handle_type_mismatch_v1"},
    {0xffffffff800000f0, "__log"},
    {0xffffffff80004a00, "printf"},
    {0xffffffff80005fe0, "vprintf"},
    {0xffffffff80000190, "halt"},
    {0xffffffff800001a0, "_start"},
    {0xffffffff800013e0, "gdt_init"},
    {0xffffffff80003490, "idt_init"},
    {0xffffffff800018e0, "pmm_init"},
    {0xffffffff80002950, "vmm_init"},
    {0xffffffff800039e0, "pic_remap"},
    {0xffffffff80000420, "__panic"},
    {0xffffffff800003b0, "outb"},
    {0xffffffff800003c0, "inb"},
    {0xffffffff800003d0, "outw"},
    {0xffffffff800003e0, "inw"},
    {0xffffffff800003f0, "outl"},
    {0xffffffff80000400, "inl"},
    {0xffffffff80000410, "io_wait"},
    {0xffffffff80001240, "symbols_get_function_name"},
    {0xffffffff80001080, "__ubsan_handle_pointer_overflow"},
    {0xffffffff80001110, "__ubsan_handle_out_of_bounds"},
    {0xffffffff80000f90, "__ubsan_handle_add_overflow"},
    {0xffffffff80000fc0, "__ubsan_handle_sub_overflow"},
    {0xffffffff80000ff0, "__ubsan_handle_mul_overflow"},
    {0xffffffff80001020, "__ubsan_handle_divrem_overflow"},
    {0xffffffff80001050, "__ubsan_handle_negate_overflow"},
    {0xffffffff800010b0, "__ubsan_handle_shift_out_of_bounds"},
    {0xffffffff800010e0, "__ubsan_handle_load_invalid_value"},
    {0xffffffff80001150, "__ubsan_handle_vla_bound_not_positive"},
    {0xffffffff80001180, "__ubsan_handle_nonnull_return"},
    {0xffffffff800011b0, "__ubsan_handle_nonnull_arg"},
    {0xffffffff800011e0, "__ubsan_handle_builtin_unreachable"},
    {0xffffffff80001210, "__ubsan_handle_invalid_builtin"},
    {0xffffffff800040d0, "memset"},
    {0xffffffff800014f0, "tss_init"},
    {0xffffffff800015a0, "tss_set_stack"},
    {0xffffffff800015b0, "bitmap_set"},
    {0xffffffff800016c0, "bitmap_unset"},
    {0xffffffff800017e0, "bitmap_check"},
    {0xffffffff800026e0, "mmap_get_entry_type"},
    {0xffffffff80002770, "pmm_free"},
    {0xffffffff800027c0, "pmm_alloc"},
    {0xffffffff80002920, "pmm_alloc_zero"},
    {0xffffffff80002fb0, "vmm_map_page"},
    {0xffffffff80002fa0, "vmm_create_page_directory"},
    {0xffffffff80003190, "vmm_activate_page_directory"},
    {0xffffffff80003310, "vmm_flush_tlb"},
    {0xffffffff80003320, "idt_set_descriptor"},
    {0xffffffff800035b0, "isr_0"},
    {0xffffffff800035e0, "isr_1"},
    {0xffffffff80003610, "isr_2"},
    {0xffffffff80003640, "isr_3"},
    {0xffffffff80003670, "isr_4"},
    {0xffffffff800036a0, "isr_5"},
    {0xffffffff800036d0, "isr_6"},
    {0xffffffff80003700, "isr_7"},
    {0xffffffff80003730, "isr_8"},
    {0xffffffff80003760, "isr_9"},
    {0xffffffff80003790, "isr_10"},
    {0xffffffff800037c0, "isr_11"},
    {0xffffffff800037f0, "isr_12"},
    {0xffffffff80003820, "isr_13"},
    {0xffffffff80003850, "isr_14"},
    {0xffffffff800039d0, "isr_reserved"},
    {0xffffffff800038b0, "isr_16"},
    {0xffffffff800038e0, "isr_17"},
    {0xffffffff80003910, "isr_18"},
    {0xffffffff80003940, "isr_19"},
    {0xffffffff80003970, "isr_20"},
    {0xffffffff800039a0, "isr_30"},
    {0xffffffff80003580, "isr_handler"},
    {0xffffffff80003880, "isr_15"},
    {0xffffffff80003ab0, "pic_eoi"},
    {0xffffffff80003ae0, "irq_set_mask"},
    {0xffffffff80003b50, "irq_clear_mask"},
    {0xffffffff80003bc0, "pic_get_irr"},
    {0xffffffff80003c10, "pic_get_isr"},
    {0xffffffff80003c90, "memchr"},
    {0xffffffff80003d10, "memcmp"},
    {0xffffffff80003ed0, "memcpy"},
    {0xffffffff80003ee0, "memmove"},
    {0xffffffff800040e0, "strchr"},
    {0xffffffff80004160, "strcpy"},
    {0xffffffff800042a0, "strncpy"},
    {0xffffffff80004450, "strlen"},
    {0xffffffff800044c0, "strcmp"},
    {0xffffffff800045d0, "strncmp"},
    {0xffffffff80004730, "strspn"},
    {0xffffffff80004850, "strcspn"},
    {0xffffffff80004960, "strtok"},
    {0xffffffff80006a10, "putc"},
    {0xffffffff80006a40, "putchar"},
    {0xffffffff80006a70, "puts"},
    {0xffffffff80005e40, "sprintf"},
    {0xffffffff80005f50, "snprintf"},
    {0xffffffff80006010, "vsnprintf"},
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
