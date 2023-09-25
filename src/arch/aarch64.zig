const std = @import("std");
const dtb = @import("dtb");

pub const mm = @import("aarch64/mm.zig");
pub const acpi = @import("aarch64/acpi.zig");

pub fn halt() void {
    while (true)
        asm volatile ("wfi");
}

pub var device_tree: u64 = 0x40000000;

pub const Spinlock = struct {
    lock_bits: std.atomic.Atomic(u32) = .{ .value = 0 },
    refcount: std.atomic.Atomic(usize) = .{ .value = 0 },

    pub fn lock(self: *Spinlock) void {
        _ = self.refcount.fetchAdd(1, .Monotonic);

        while (true) {
            if (self.lock_bits.swap(1, .Acquire) == 0)
                break;

            while (self.lock_bits.fetchAdd(0, .Monotonic) != 0) {
                std.atomic.spinLoopHint();
            }
        }

        _ = self.refcount.fetchSub(1, .Monotonic);
        std.atomic.compilerFence(.Acquire);
    }

    pub fn unlock(self: *Spinlock) void {
        self.lock_bits.store(0, .Release);
        std.atomic.compilerFence(.Release);
    }
};
