const std = @import("std");

pub const mm = @import("x86_64/mm.zig");
pub const acpi = @import("x86_64/acpi.zig");

pub fn interruptsEnabled() bool {
    var eflags = asm volatile (
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

pub const Spinlock = struct {
    lock_bits: std.atomic.Atomic(u32) = .{ .value = 0 },
    refcount: std.atomic.Atomic(usize) = .{ .value = 0 },
    interrupts: bool = false,

    pub fn acq(self: *Spinlock) void {
        _ = self.refcount.fetchAdd(1, .Monotonic);

        var current = interruptsEnabled();
        disableInterrupts();

        while (true) {
            // ------------------------------------------------
            // x86 Instruction | Micro ops | Base Latency
            // ------------------------------------------------
            // XCHG                  8           23
            // LOCK XADD             9           18
            // LOCK CMPXCHG          10          18
            // LOCK CMPXCHG8B        20          19
            // ------------------------------------------------
            // We're optimizing for micro ops, since base
            // latency isn't consistent across CPU families.
            // Therefore, we go with the XCHG instruction...
            // ------------------------------------------------
            // Source: https://agner.org/optimize/instruction_tables.pdf
            //
            if (self.lock_bits.swap(1, .Acquire) == 0) {
                // 'self.lock_bits.swap' translates to a XCHG
                break;
            }

            while (self.lock_bits.fetchAdd(0, .Monotonic) != 0) {
                // IRQs can be recived while waiting
                // for the lock to be available...

                if (interruptsEnabled()) enableInterrupts() else disableInterrupts();

                std.atomic.spinLoopHint();
                disableInterrupts();
            }
        }

        _ = self.refcount.fetchSub(1, .Monotonic);
        std.atomic.compilerFence(.Acquire);
        self.interrupts = current;
    }

    pub fn rel(self: *Spinlock) void {
        self.lock_bits.store(0, .Release);
        std.atomic.compilerFence(.Release);

        if (self.interrupts) enableInterrupts() else disableInterrupts();
    }

    // wrappers for zig stdlib
    pub inline fn lock(self: *Spinlock) void {
        self.acq();
    }

    pub inline fn unlock(self: *Spinlock) void {
        self.rel();
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
          [subleaf] "{ecx}" (sub_leaf),
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
