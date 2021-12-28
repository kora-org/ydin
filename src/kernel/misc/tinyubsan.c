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

#include <stdint.h>
#include <stddef.h>
#include <kernel/panic.h>

struct tu_source_location {
    const char *file;
    uint32_t line;
    uint32_t column;
};

struct tu_type_descriptor {
    uint16_t kind;
    uint16_t info;
    char name[];
};

struct tu_overflow_data {
    struct tu_source_location location;
    struct tu_type_descriptor *type;
};

struct tu_shift_out_of_bounds_data {
    struct tu_source_location location;
    struct tu_type_descriptor *left_type;
    struct tu_type_descriptor *right_type;
};

struct tu_invalid_value_data {
    struct tu_source_location location;
    struct tu_type_descriptor *type;
};

struct tu_array_out_of_bounds_data {
    struct tu_source_location location;
    struct tu_type_descriptor *array_type;
    struct tu_type_descriptor *index_type;
};

struct tu_type_mismatch_v1_data {
    struct tu_source_location location;
    struct tu_type_descriptor *type;
    unsigned char log_alignment;
    unsigned char type_check_kind;
};

struct tu_negative_vla_data {
    struct tu_source_location location;
    struct tu_type_descriptor *type;
};

struct tu_nonnull_return_data {
    struct tu_source_location location;
};

struct tu_nonnull_arg_data {
    struct tu_source_location location;
};

struct tu_unreachable_data {
    struct tu_source_location location;
};

struct tu_invalid_builtin_data {
    struct tu_source_location location;
    unsigned char kind;
};

static void tu_print_location(char *message, struct tu_source_location loc) {
    __panic(loc.file, loc.line, 0, NULL, message);
}

void __ubsan_handle_add_overflow(struct tu_overflow_data *data) {
    tu_print_location("addition overflow", data->location);
}

void __ubsan_handle_sub_overflow(struct tu_overflow_data *data) {
    tu_print_location("subtraction overflow", data->location);
}

void __ubsan_handle_mul_overflow(struct tu_overflow_data *data) {
    tu_print_location("multiplication overflow", data->location);
}

void __ubsan_handle_divrem_overflow(struct tu_overflow_data *data) {
    tu_print_location("division overflow", data->location);
}

void __ubsan_handle_negate_overflow(struct tu_overflow_data *data) {
    tu_print_location("negation overflow", data->location);
}

void __ubsan_handle_pointer_overflow(struct tu_overflow_data *data) {
    tu_print_location("pointer overflow", data->location);
}

void __ubsan_handle_shift_out_of_bounds(struct tu_shift_out_of_bounds_data *data) {
    tu_print_location("shift out of bounds", data->location);
}

void __ubsan_handle_load_invalid_value(struct tu_invalid_value_data *data) {
    tu_print_location("invalid load value", data->location);
}

void __ubsan_handle_out_of_bounds(struct tu_array_out_of_bounds_data *data) {
    tu_print_location("array out of bounds", data->location);
}

void __ubsan_handle_type_mismatch_v1(struct tu_type_mismatch_v1_data *data, uintptr_t ptr) {
    // temporrarily commenting this so pmm can work
    /*if (!ptr) {
        tu_print_location("use of NULL pointer", data->location);
    } else if (ptr & ((1 << data->log_alignment) - 1)) {
        tu_print_location("use of misaligned pointer", data->location);
    } else {
        tu_print_location("no space for object", data->location);
    }*/
}

void __ubsan_handle_vla_bound_not_positive(struct tu_negative_vla_data *data) {
    tu_print_location("variable-length argument is negative", data->location);
}

void __ubsan_handle_nonnull_return(struct tu_nonnull_return_data *data) {
    tu_print_location("non-null return is null", data->location);
}

void __ubsan_handle_nonnull_arg(struct tu_nonnull_arg_data *data) {
    tu_print_location("non-null argument is null", data->location);
}

void __ubsan_handle_builtin_unreachable(struct tu_unreachable_data *data) {
    tu_print_location("unreachable code reached", data->location);
}

void __ubsan_handle_invalid_builtin(struct tu_invalid_builtin_data *data) {
    tu_print_location("invalid builtin", data->location);
}
