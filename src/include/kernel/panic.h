#pragma once
#include <stdint.h>
#include <kernel/isr.h>

void __panic(char *file, int line, int is_isr, exception_t *exception, char *message, ...);
#define panic(msg...) __panic(__FILE_NAME__, __LINE__, 0, NULL, msg);
#define isr_panic(rsp, msg...) __panic(__FILE_NAME__, __LINE__, 1, rsp, msg);
