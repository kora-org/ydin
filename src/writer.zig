const std = @import("std");
const builtin = @import("builtin");
const arch = @import("arch.zig");

const DefaultWriter = switch (builtin.cpu.arch) {
    .x86_64 => @import("arch/x86_64/serial.zig"),
    .aarch64 => @import("arch/aarch64/serial.zig").Serial,
    else => unreachable,
};

pub fn init() void {
    const serial = switch (builtin.cpu.arch) {
        .x86_64 => DefaultWriter{},
        .aarch64 => DefaultWriter() catch unreachable,
        else => unreachable,
    };
    serial.init();
}

pub fn write(_: *anyopaque, bytes: []const u8) !usize {
    const serial = switch (builtin.cpu.arch) {
        .x86_64 => DefaultWriter{},
        .aarch64 => try DefaultWriter(),
        else => unreachable,
    };
    return serial.write(bytes);
}

pub const writer = std.io.Writer(
    *anyopaque,
    anyerror,
    write,
){ .context = undefined };
