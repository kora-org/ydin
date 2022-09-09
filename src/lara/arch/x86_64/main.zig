const std = @import("std");
const limine = @import("limine");
const arch = @import("arch");
const lara = @import("../../main.zig");
const writer = @import("../../writer.zig");

pub export var terminal_request: limine.Terminal.Request = .{};
pub var terminal_response: limine.Terminal.Response = undefined;

pub fn log(comptime message_level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch unreachable;
}

pub export fn _start() callconv(.C) void {
    if (terminal_request.response) |terminal| {
        terminal_response = terminal.*;

        if (terminal_response.terminal_count < 1) {
            arch.halt();
        }
    }

    lara.main();
    arch.halt();
}
