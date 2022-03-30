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

#include <kernel/symbols.h>

sym_table_t symbol_table[] = {
    {0xffffffff80000e70, "__panic_log"},
    {0xffffffff80003080, "vmm_get_next_level"},
    {0xffffffff80006170, "_out_char"},
    {0xffffffff80004e00, "_vsnprintf"},
    {0xffffffff80006430, "_out_null"},
    {0xffffffff80006440, "_atoi"},
    {0xffffffff80006510, "_ntoa_format"},
    {0xffffffff800061f0, "_out_buffer"},
    {0xffffffff80006380, "_out_fct"},
    {0xffffffff80000000, "stivale2_get_tag"},
    {0xffffffff800011a0, "__ubsan_handle_type_mismatch_v1"},
    {0xffffffff80000100, "__log"},
    {0xffffffff80004d90, "printf"},
    {0xffffffff800062c0, "vprintf"},
    {0xffffffff80000160, "halt"},
    {0xffffffff80000170, "_start"},
    {0xffffffff80001520, "gdt_init"},
    {0xffffffff80003500, "idt_init"},
    {0xffffffff80001900, "pmm_init"},
    {0xffffffff80002790, "vmm_init"},
    {0xffffffff80003a50, "pic_remap"},
    {0xffffffff80002e70, "vmm_create_page_dir"},
    {0xffffffff80000370, "io_outb"},
    {0xffffffff80000380, "io_inb"},
    {0xffffffff80000390, "io_outw"},
    {0xffffffff800003a0, "io_inw"},
    {0xffffffff800003b0, "io_outl"},
    {0xffffffff800003c0, "io_inl"},
    {0xffffffff800003d0, "io_wait"},
    {0xffffffff800003e0, "__panic"},
    {0xffffffff80001340, "symbols_get_function_name"},
    {0xffffffff80001060, "__ubsan_handle_pointer_overflow"},
    {0xffffffff80001150, "__ubsan_handle_out_of_bounds"},
    {0xffffffff80000ed0, "__ubsan_handle_add_overflow"},
    {0xffffffff80000f20, "__ubsan_handle_sub_overflow"},
    {0xffffffff80000f70, "__ubsan_handle_mul_overflow"},
    {0xffffffff80000fc0, "__ubsan_handle_divrem_overflow"},
    {0xffffffff80001010, "__ubsan_handle_negate_overflow"},
    {0xffffffff800010b0, "__ubsan_handle_shift_out_of_bounds"},
    {0xffffffff80001100, "__ubsan_handle_load_invalid_value"},
    {0xffffffff800011b0, "__ubsan_handle_vla_bound_not_positive"},
    {0xffffffff80001200, "__ubsan_handle_nonnull_return"},
    {0xffffffff80001250, "__ubsan_handle_nonnull_arg"},
    {0xffffffff800012a0, "__ubsan_handle_builtin_unreachable"},
    {0xffffffff800012f0, "__ubsan_handle_invalid_builtin"},
    {0xffffffff80004240, "memset"},
    {0xffffffff80001620, "tss_init"},
    {0xffffffff800016c0, "tss_set_stack"},
    {0xffffffff800016d0, "bitmap_set"},
    {0xffffffff80001790, "bitmap_unset"},
    {0xffffffff80001850, "bitmap_check"},
    {0xffffffff80002520, "mmap_get_entry_type"},
    {0xffffffff800025b0, "pmm_free"},
    {0xffffffff80002600, "pmm_alloc"},
    {0xffffffff80002760, "pmm_alloc_zero"},
    {0xffffffff80002e80, "vmm_map_page"},
    {0xffffffff80003070, "vmm_activate_page_dir"},
    {0xffffffff800031e0, "vmm_flush_tlb"},
    {0xffffffff800031f0, "vmm_unmap_page"},
    {0xffffffff800033c0, "idt_set_descriptor"},
    {0xffffffff80003620, "isr_0"},
    {0xffffffff80003650, "isr_1"},
    {0xffffffff80003680, "isr_2"},
    {0xffffffff800036b0, "isr_3"},
    {0xffffffff800036e0, "isr_4"},
    {0xffffffff80003710, "isr_5"},
    {0xffffffff80003740, "isr_6"},
    {0xffffffff80003770, "isr_7"},
    {0xffffffff800037a0, "isr_8"},
    {0xffffffff800037d0, "isr_9"},
    {0xffffffff80003800, "isr_10"},
    {0xffffffff80003830, "isr_11"},
    {0xffffffff80003860, "isr_12"},
    {0xffffffff80003890, "isr_13"},
    {0xffffffff800038c0, "isr_14"},
    {0xffffffff80003a40, "isr_reserved"},
    {0xffffffff80003920, "isr_16"},
    {0xffffffff80003950, "isr_17"},
    {0xffffffff80003980, "isr_18"},
    {0xffffffff800039b0, "isr_19"},
    {0xffffffff800039e0, "isr_20"},
    {0xffffffff80003a10, "isr_30"},
    {0xffffffff800035f0, "isr_handler"},
    {0xffffffff800038f0, "isr_15"},
    {0xffffffff80003b20, "pic_eoi"},
    {0xffffffff80003b50, "irq_set_mask"},
    {0xffffffff80003bc0, "irq_clear_mask"},
    {0xffffffff80003c30, "pic_get_irr"},
    {0xffffffff80003c80, "pic_get_isr"},
    {0xffffffff80003d00, "memchr"},
    {0xffffffff80003d90, "memcmp"},
    {0xffffffff80003f90, "memcpy"},
    {0xffffffff80003fa0, "memmove"},
    {0xffffffff80004250, "strchr"},
    {0xffffffff800042e0, "strcpy"},
    {0xffffffff80004440, "strncpy"},
    {0xffffffff80004640, "strlen"},
    {0xffffffff800046d0, "strcmp"},
    {0xffffffff80004830, "strncmp"},
    {0xffffffff800049d0, "strspn"},
    {0xffffffff80004b70, "strcspn"},
    {0xffffffff80004cf0, "strtok"},
    {0xffffffff80006cb0, "putchar"},
    {0xffffffff80006ce0, "puts"},
    {0xffffffff80006190, "sprintf"},
    {0xffffffff80006260, "snprintf"},
    {0xffffffff800062f0, "vsnprintf"},
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
