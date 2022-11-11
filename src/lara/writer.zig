const std = @import("std");
const builtin = @import("builtin");

const DefaultWriter = switch (builtin.cpu.arch) {
    .x86_64 => @import("arch/x86_64/serial.zig").Serial(0x3f8),
    else => unreachable,
};

pub fn init() void {
    switch (builtin.cpu.arch) {
        .x86_64 => DefaultWriter.init(DefaultWriter{}),
        else => unreachable,
    }
}

pub const writer = std.io.Writer(
    DefaultWriter,
    DefaultWriter.Error,
    DefaultWriter.write,
){ .context = DefaultWriter{} };
