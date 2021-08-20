#include <stdint.h>

// Alignment must be a power of 2.
#define is_aligned(value, alignment) !(value & (alignment - 1))

struct source_location {
    const char *file;
    uint32_t line;
    uint32_t column;
};
 
struct type_descriptor {
    uint16_t kind;
    uint16_t info;
    char name[];
};
 
struct type_mismatch_info {
    struct source_location location;
    struct type_descriptor *type;
    uintptr_t alignment;
    uint8_t type_check_kind;
};
 
struct out_of_bounds_info {
    struct source_location location;
    struct type_descriptor left_type;
    struct type_descriptor right_type;
};

void __ubsan_handle_type_mismatch(struct type_mismatch_info *type_mismatch,
                                  uintptr_t pointer);
