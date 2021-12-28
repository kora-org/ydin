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
    {0xffffffff80000f20, "__panic_log"},
    {0xffffffff800032a0, "vmm_get_next_level"},
    {0xffffffff80005f20, "_out_char"},
    {0xffffffff80004bb0, "_vsnprintf"},
    {0xffffffff80006280, "_out_null"},
    {0xffffffff80006290, "_atoi"},
    {0xffffffff80006360, "_ntoa_format"},
    {0xffffffff80005fe0, "_out_buffer"},
    {0xffffffff800061d0, "_out_fct"},
    {0xffffffff80000000, "stivale2_get_tag"},
    {0xffffffff80001170, "__ubsan_handle_type_mismatch_v1"},
    {0xffffffff800000f0, "__log"},
    {0xffffffff80004b00, "printf"},
    {0xffffffff800060e0, "vprintf"},
    {0xffffffff80000190, "halt"},
    {0xffffffff800001a0, "_start"},
    {0xffffffff80001410, "gdt_init"},
    {0xffffffff80003590, "idt_init"},
    {0xffffffff80001910, "pmm_init"},
    {0xffffffff80002a50, "vmm_init"},
    {0xffffffff80003ae0, "pic_remap"},
    {0xffffffff80000420, "__panic"},
    {0xffffffff800003b0, "outb"},
    {0xffffffff800003c0, "inb"},
    {0xffffffff800003d0, "outw"},
    {0xffffffff800003e0, "inw"},
    {0xffffffff800003f0, "outl"},
    {0xffffffff80000400, "inl"},
    {0xffffffff80000410, "io_wait"},
    {0xffffffff80001270, "symbols_get_function_name"},
    {0xffffffff800010b0, "__ubsan_handle_pointer_overflow"},
    {0xffffffff80001140, "__ubsan_handle_out_of_bounds"},
    {0xffffffff80000fc0, "__ubsan_handle_add_overflow"},
    {0xffffffff80000ff0, "__ubsan_handle_sub_overflow"},
    {0xffffffff80001020, "__ubsan_handle_mul_overflow"},
    {0xffffffff80001050, "__ubsan_handle_divrem_overflow"},
    {0xffffffff80001080, "__ubsan_handle_negate_overflow"},
    {0xffffffff800010e0, "__ubsan_handle_shift_out_of_bounds"},
    {0xffffffff80001110, "__ubsan_handle_load_invalid_value"},
    {0xffffffff80001180, "__ubsan_handle_vla_bound_not_positive"},
    {0xffffffff800011b0, "__ubsan_handle_nonnull_return"},
    {0xffffffff800011e0, "__ubsan_handle_nonnull_arg"},
    {0xffffffff80001210, "__ubsan_handle_builtin_unreachable"},
    {0xffffffff80001240, "__ubsan_handle_invalid_builtin"},
    {0xffffffff800041d0, "memset"},
    {0xffffffff80001520, "tss_init"},
    {0xffffffff800015d0, "tss_set_stack"},
    {0xffffffff800015e0, "bitmap_set"},
    {0xffffffff800016f0, "bitmap_unset"},
    {0xffffffff80001810, "bitmap_check"},
    {0xffffffff80002710, "mmap_get_entry_type"},
    {0xffffffff800027a0, "pmm_free"},
    {0xffffffff800027f0, "pmm_find_first_free_page"},
    {0xffffffff800028c0, "pmm_alloc"},
    {0xffffffff80002a20, "pmm_alloc_zero"},
    {0xffffffff800030b0, "vmm_map_page"},
    {0xffffffff800030a0, "vmm_create_page_directory"},
    {0xffffffff80003290, "vmm_activate_page_directory"},
    {0xffffffff80003410, "vmm_flush_tlb"},
    {0xffffffff80003420, "idt_set_descriptor"},
    {0xffffffff800036b0, "isr_0"},
    {0xffffffff800036e0, "isr_1"},
    {0xffffffff80003710, "isr_2"},
    {0xffffffff80003740, "isr_3"},
    {0xffffffff80003770, "isr_4"},
    {0xffffffff800037a0, "isr_5"},
    {0xffffffff800037d0, "isr_6"},
    {0xffffffff80003800, "isr_7"},
    {0xffffffff80003830, "isr_8"},
    {0xffffffff80003860, "isr_9"},
    {0xffffffff80003890, "isr_10"},
    {0xffffffff800038c0, "isr_11"},
    {0xffffffff800038f0, "isr_12"},
    {0xffffffff80003920, "isr_13"},
    {0xffffffff80003950, "isr_14"},
    {0xffffffff80003ad0, "isr_reserved"},
    {0xffffffff800039b0, "isr_16"},
    {0xffffffff800039e0, "isr_17"},
    {0xffffffff80003a10, "isr_18"},
    {0xffffffff80003a40, "isr_19"},
    {0xffffffff80003a70, "isr_20"},
    {0xffffffff80003aa0, "isr_30"},
    {0xffffffff80003680, "isr_handler"},
    {0xffffffff80003980, "isr_15"},
    {0xffffffff80003bb0, "pic_eoi"},
    {0xffffffff80003be0, "irq_set_mask"},
    {0xffffffff80003c50, "irq_clear_mask"},
    {0xffffffff80003cc0, "pic_get_irr"},
    {0xffffffff80003d10, "pic_get_isr"},
    {0xffffffff80003d90, "memchr"},
    {0xffffffff80003e10, "memcmp"},
    {0xffffffff80003fd0, "memcpy"},
    {0xffffffff80003fe0, "memmove"},
    {0xffffffff800041e0, "strchr"},
    {0xffffffff80004260, "strcpy"},
    {0xffffffff800043a0, "strncpy"},
    {0xffffffff80004550, "strlen"},
    {0xffffffff800045c0, "strcmp"},
    {0xffffffff800046d0, "strncmp"},
    {0xffffffff80004830, "strspn"},
    {0xffffffff80004950, "strcspn"},
    {0xffffffff80004a60, "strtok"},
    {0xffffffff80006b10, "putc"},
    {0xffffffff80006b40, "putchar"},
    {0xffffffff80006b70, "puts"},
    {0xffffffff80005f40, "sprintf"},
    {0xffffffff80006050, "snprintf"},
    {0xffffffff80006110, "vsnprintf"},
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
