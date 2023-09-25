const std = @import("std");
const limine = @import("limine");
const arch = @import("../riscv64.zig");
const writer = @import("../../writer.zig");
const lara = @import("../../main.zig");
pub const panic = @import("panic.zig").panic;

pub const std_options = struct {
    pub fn logFn(comptime level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        const scope_prefix = if (scope == .default) "main" else @tagName(scope);
        const prefix = "\x1b[32m[lara:" ++ scope_prefix ++ "] " ++ switch (level) {
            .err => "\x1b[31merror",
            .warn => "\x1b[33mwarning",
            .info => "\x1b[36minfo",
            .debug => "\x1b[90mdebug",
        } ++ ": \x1b[0m";
        writer.writer.print(prefix ++ format ++ "\n", args) catch unreachable;
    }
};

pub export var dtb_request: limine.DeviceTree.Request = .{};
pub export fn _start() callconv(.C) void {
    if (dtb_request.response) |dtb|
        arch.device_tree = dtb.address;

    writer.init();
    lara.main() catch unreachable;
    arch.halt();
}
