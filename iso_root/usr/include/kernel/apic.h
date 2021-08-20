#include <stdint.h>
#include <stdbool.h>

#define IA32_APIC_BASE_MSR 0x1B
#define IA32_APIC_BASE_MSR_BSP 0x100 // Processor is a BSP
#define IA32_APIC_BASE_MSR_ENABLE 0x800

bool check_apic();
void cpu_set_apic_base(uintptr_t apic);
uintptr_t cpu_get_apic_base();
void enable_apic();

#define IOAPICID          0x00
#define IOAPICVER         0x01
#define IOAPICARB         0x02
#define IOAPICREDTBL(n)   (0x10 + 2 * n) // lower-32bits (add +1 for upper 32-bits)

void write_ioapic_register(const uintptr_t apic_base, const uint8_t offset, const uint32_t val);
uint32_t read_ioapic_register(const uintptr_t apic_base, const uint8_t offset);
