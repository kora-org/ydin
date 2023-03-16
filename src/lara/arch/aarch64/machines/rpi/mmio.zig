const arch = @import("../../../aarch64.zig");

pub fn getMmioBase() !u64 {
    return switch (try arch.getBoardType()) {
        .RaspberryPi3 => 0x3f000000,
        .RaspberryPi4 => 0xfe000000,
        else => error.NotAPi,
    };
}

pub fn write(reg: u64, data: u32) void {
    @fence(.SeqCst);
    @intToPtr(*volatile u32, reg).* = data;
}

pub fn read(reg: u64) u32 {
    @fence(.SeqCst);
    return @intToPtr(*volatile u32, reg).*;
}
