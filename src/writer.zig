const std = @import("std");
const builtin = @import("builtin");
const arch = @import("arch.zig");

var lock = arch.Spinlock{};

const DefaultWriter = switch (builtin.cpu.arch) {
    .x86_64 => @import("arch/x86_64/serial.zig"),
    .aarch64 => @import("arch/aarch64/serial.zig").Serial,
    else => unreachable,
};

pub fn init() void {
    lock.lock();
    defer lock.unlock();

    const default_writer = switch (builtin.cpu.arch) {
        .x86_64 => DefaultWriter{},
        .aarch64 => DefaultWriter() catch unreachable,
        else => unreachable,
    };
    default_writer.init();
}

pub fn write(_: *anyopaque, bytes: []const u8) anyerror!usize {
    lock.lock();
    defer lock.unlock();

    const default_writer = switch (builtin.cpu.arch) {
        .x86_64 => DefaultWriter{},
        .aarch64 => try DefaultWriter(),
        else => unreachable,
    };
    return default_writer.write(bytes);
}

pub const writer = std.io.Writer(
    *anyopaque,
    anyerror,
    write,
){ .context = undefined };
