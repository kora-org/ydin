#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint64_t address;
    const char *function_name;
} sym_table_t;

const char *symbols_get_function_name(uint64_t address);
