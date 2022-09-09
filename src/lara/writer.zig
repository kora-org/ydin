const std = @import("std");
const builtin = @import("builtin");

const DefaultWriter = switch (builtin.cpu.arch) {
    .x86_64 => @import("arch/x86_64/main.zig").terminal_response.writer,
    else => unreachable,
};

const ContextType = switch (builtin.cpu.arch) {
    .x86_64 => ?*@import("limine").Terminal.Term,
    else => unreachable,
};

const context = switch (builtin.cpu.arch) {
    .x86_64 => @import("arch/x86_64/main.zig").terminal_response.terminals[0],
    else => unreachable,
};

fn write(_context: ContextType, bytes: []const u8) void {
    _ = try DefaultWriter(_context).write(bytes);
}

pub usingnamespace std.io.Writer(
    ContextType,
    DefaultWriter.Error,
    write,
){ .context = context };
