const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const arch = @import("arch.zig");
const psf = @import("psf.zig");
const writer = @import("writer.zig");
//pub const panic = arch.panic.panic;

pub const std_options = struct {
    pub fn logFn(comptime level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        const scope_prefix = if (scope == .default) "main" else @tagName(scope);
        const prefix = "\x1b[32m[ydin:" ++ scope_prefix ++ "] " ++ switch (level) {
            .err => "\x1b[31merror",
            .warn => "\x1b[33mwarning",
            .info => "\x1b[36minfo",
            .debug => "\x1b[90mdebug",
        } ++ ": \x1b[0m";
        writer.writer.print(prefix ++ format ++ "\n", args) catch unreachable;
    }
};

comptime {
    @export(arch.main.start, .{ .name = "_start", .linkage = .Strong });
}

pub fn main() !void {
    std.log.info("\x1b[94mKora\x1b[0m version {s}", .{build_options.version});
    std.log.info("Compiled with Zig v{}", .{builtin.zig_version});
    std.log.info("All your {s} are belong to us.", .{"codebase"});
    arch.mm.pmm.init();
    arch.mm.vmm.init();
    arch.acpi.init();
    @panic("test");
}
