const std = @import("std");

pub const cpu = @import("x86_64/cpu.zig");
pub const main = @import("x86_64/main.zig");
pub const acpi = @import("x86_64/acpi.zig");
pub const smp = @import("x86_64/smp.zig");
pub const sched = @import("x86_64/sched.zig");
pub const vmm = @import("x86_64/vmm.zig");

pub fn interruptsEnabled() bool {
    const eflags = asm volatile (
        \\pushf
        \\pop %[result]
        : [result] "=r" (-> u64),
    );

    return ((eflags & 0x200) != 0);
}

pub fn enableInterrupts() void {
    asm volatile ("sti");
}

pub fn disableInterrupts() void {
    asm volatile ("cli");
}

pub fn pause() void {
    asm volatile ("pause" ::: "memory");
}

pub fn halt() void {
    disableInterrupts();
    while (true) {
        asm volatile ("hlt");
    }
}

pub const Spinlock = extern struct {
    lock_bits: std.atomic.Value(u32) = .{ .raw = 0 },
    refcount: std.atomic.Value(usize) = .{ .raw = 0 },
    interrupts: bool = false,

    pub fn lock(self: *Spinlock) void {
        _ = self.refcount.fetchAdd(1, .monotonic);

        const current = interruptsEnabled();
        disableInterrupts();

        while (true) {
            if (self.lock_bits.swap(1, .acquire) == 0)
                break;

            while (self.lock_bits.fetchAdd(0, .monotonic) != 0) {
                if (interruptsEnabled())
                    enableInterrupts()
                else
                    disableInterrupts();

                std.atomic.spinLoopHint();
                disableInterrupts();
            }
        }

        _ = self.refcount.fetchSub(1, .monotonic);
        @fence(.acquire);
        self.interrupts = current;
    }

    pub fn unlock(self: *Spinlock) void {
        self.lock_bits.store(0, .release);
        @fence(.release);

        if (self.interrupts)
            enableInterrupts()
        else
            disableInterrupts();
    }
};

/// x86 specific stuff
pub const io = @import("x86_64/io.zig");
pub const cr = @import("x86_64/cr.zig");

pub const Descriptor = packed struct {
    size: u16,
    ptr: u64,
};

pub const CpuidResult = struct {
    eax: u32,
    ebx: u32,
    ecx: u32,
    edx: u32,
};

pub fn cpuid(leaf: u32, sub_leaf: u32) CpuidResult {
    var eax: u32 = undefined;
    var ebx: u32 = undefined;
    var ecx: u32 = undefined;
    var edx: u32 = undefined;

    asm volatile ("cpuid"
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx),
        : [leaf] "{eax}" (leaf),
          [sub_leaf] "{ecx}" (sub_leaf),
        : "memory"
    );

    return .{
        .eax = eax,
        .ebx = ebx,
        .ecx = ecx,
        .edx = edx,
    };
}

pub fn rdtsc() u64 {
    var low: u32 = undefined;
    var high: u32 = undefined;

    asm volatile ("rdtsc"
        : [_] "={eax}" (low),
          [_] "={edx}" (high),
    );

    return @as(u64, low) | (@as(u64, high) << 32);
}

pub fn wrmsr(reg: u64, val: u64) void {
    asm volatile ("wrmsr"
        :
        : [_] "{eax}" (val & 0xFFFFFFFF),
          [_] "{edx}" (val >> 32),
          [_] "{ecx}" (reg),
    );
}

pub fn rdmsr(reg: u64) u64 {
    var low: u32 = undefined;
    var high: u32 = undefined;

    asm volatile ("rdmsr"
        : [_] "={eax}" (low),
          [_] "={edx}" (high),
        : [_] "{ecx}" (reg),
    );

    return @as(u64, low) | (@as(u64, high) << 32);
}
