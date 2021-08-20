#include <stdio.h>
#include <stdint.h>
#include <kernel/ubsan.h>
#include <kernel/panic.h>

const char *Type_Check_Kinds[] = {
    "load of",
    "store to",
    "reference binding to",
    "member access within",
    "member call on",
    "constructor call on",
    "downcast of",
    "downcast of",
    "upcast of",
    "cast to virtual base of",
};
 
static void log_location(struct source_location *location) {
    printf("ubsan: \tfile: %s\n\tline: %i\n\tcolumn: %i\n",
           location->file, location->line, location->column);
}
 
 
void __ubsan_handle_type_mismatch(struct type_mismatch_info *type_mismatch,
                                  uintptr_t pointer) {
    struct source_location *location = &type_mismatch->location;
    if (pointer == 0) {
        printf("ubsan: null pointer access");
    } else if (type_mismatch->alignment != 0 &&
               is_aligned(pointer, type_mismatch->alignment)) {
        // Most useful on architectures with stricter memory alignment requirements, like ARM.
        printf("ubsan: unaligned memory access");
    } else {
        printf("ubsan: insufficient size");
        printf("ubsan: %s address 0x%p with insufficient space for object of type %s\n",
               Type_Check_Kinds[type_mismatch->type_check_kind], (void *)pointer,
               type_mismatch->type->name);
    }
    log_location(location);
 
    panic("ubsan: type mismatch");
}
