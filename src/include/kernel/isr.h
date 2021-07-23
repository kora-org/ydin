#pragma once

#include <kernel/idt.h>

#ifdef __cplusplus
extern "C" {
#endif

void isr_install(void);

#ifdef __cplusplus
}
#endif
