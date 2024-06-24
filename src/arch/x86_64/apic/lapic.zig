const std = @import("std");
const acpi = @import("../acpi.zig");
const pmm = @import("../../../mm/pmm.zig");
const vmm = @import("../vmm.zig");
const smp = @import("../smp.zig");
const arch = @import("../../x86_64.zig");
const log = std.log.scoped(.lapic);

const TimerMode = enum(u4) {
    Tsc,
    Lapic,
    Unknown,
};

var mmio_base: u64 = 0;
var tsc_mode: TimerMode = .Unknown;

// general regs
const REG_VER = 0x30;
const REG_EOI = 0xb0;
const REG_SPURIOUS = 0xf0;

// timer regs
const REG_TIMER_LVT = 0x320;
const REG_TIMER_INIT = 0x380;
const REG_TIMER_CNT = 0x390;
const REG_TIMER_DIV = 0x3e0;

pub fn read(reg: u32) u32 {
    return @as(*volatile u32, @ptrFromInt(mmio_base + reg)).*;
}

pub fn write(reg: u32, value: u32) void {
    @as(*volatile u32, @ptrFromInt(mmio_base + reg)).* = value;
}

inline fn canUseTsc() bool {
    if (tsc_mode == .Lapic) {
        return false;
    } else if (tsc_mode == .Tsc) {
        return true;
    } else {
        if (arch.cpuid(0x1, 0).ecx & (1 << 24) == 0 and
            arch.cpuid(0x80000007, 0).edx & (1 << 8) == 0)
        {
            tsc_mode = .Tsc;
            return true;
        } else {
            tsc_mode = .Lapic;
            return false;
        }
    }
}

pub fn enable() void {
    if (mmio_base == 0)
        mmio_base = (arch.rdmsr(0x1b) & 0xfffff000) + pmm.hhdm_response.offset;

    // enable the APIC
    arch.wrmsr(0x1b, arch.rdmsr(0x1b) | (1 << 11));
    write(REG_SPURIOUS, read(REG_SPURIOUS) | (1 << 8) | 0xff);

    if (canUseTsc()) {
        const initial = arch.rdtsc();

        // since AMD requires a "mfence" instruction to serialize the
        // TSC, and Intel requires a "lfence", use both here (not a big
        // deal since this is the only place where we need a serializing TSC)
        asm volatile ("mfence; lfence" ::: "memory");

        acpi.pmSleep(1000);
        const final = arch.rdtsc();
        asm volatile ("mfence; lfence" ::: "memory");

        smp.getCoreInfo().ticks_per_ms = final - initial;
    } else {
        // on certain platforms (simics and some KVM machines), the
        // timer starts counting as soon as the APIC is enabled.
        // therefore, we must stop the timer before calibration...
        write(REG_TIMER_INIT, 0);

        // calibrate the APIC timer (using a 10ms sleep)
        write(REG_TIMER_DIV, 0x3);
        write(REG_TIMER_LVT, 0xff | (1 << 16));
        write(REG_TIMER_INIT, std.math.maxInt(u32));
        acpi.pmSleep(1000);

        // set the frequency, then set the timer back to a disabled state
        smp.getCoreInfo().ticks_per_ms = std.math.maxInt(u32) - read(REG_TIMER_CNT);
        write(REG_TIMER_INIT, 0);
        write(REG_TIMER_LVT, (1 << 16));
    }
}

pub fn submitEoi(irq: u8) void {
    _ = irq;
    write(REG_EOI, 0);
}

pub fn oneshot(vec: u8, ms: u64) void {
    // stop the timer
    write(REG_TIMER_INIT, 0);
    write(REG_TIMER_LVT, (1 << 16));

    // set the deadline, and off we go!
    const deadline: u32 = @truncate(smp.getCoreInfo().ticks_per_ms * ms);

    if (canUseTsc()) {
        write(REG_TIMER_LVT, @as(u32, vec) | (1 << 18));
        arch.wrmsr(0x6e0, deadline);
    } else {
        write(REG_TIMER_LVT, vec);
        write(REG_TIMER_INIT, deadline);
    }
}
