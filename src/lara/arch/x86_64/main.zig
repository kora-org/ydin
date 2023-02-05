const std = @import("std");
pub const limine = @import("limine");
const arch = @import("../x86_64.zig");
const gdt = @import("gdt.zig");
const interrupt = @import("interrupt.zig");
const lara = @import("../../main.zig");
const writer = @import("../../writer.zig");
pub const panic = @import("panic.zig").panic;

pub export var framebuffer_request: limine.Framebuffer.Request = .{};
pub var framebuffer_response: limine.Framebuffer.Response = undefined;

pub const std_options = struct {
    pub const logFn = log;
};

pub fn log(comptime level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    const scope_prefix = if (scope == .default) "lara" else @tagName(scope);
    const prefix = "\x1b[32m[" ++ scope_prefix ++ "] " ++ switch (level) {
        .err => "\x1b[31merror",
        .warn => "\x1b[33mwarning",
        .info => "\x1b[36minfo",
        .debug => "\x1b[90mdebug",
    } ++ ": \x1b[0m";
    writer.writer.print(prefix ++ format ++ "\n", args) catch unreachable;
}

pub const os = .{
    .heap = .{
        .page_allocator = arch.mm.slab.allocator,
    },
};

pub export fn _start() callconv(.C) void {
    if (framebuffer_request.response) |framebuffer| {
        framebuffer_response = framebuffer.*;

        if (framebuffer_response.framebuffer_count < 1) {
            arch.halt();
        }
    }

    // Initialize x87 FPU
    asm volatile ("fninit");

    // Enable SSE
    var cr0 = arch.cr.read(0);
    cr0 &= ~(@intCast(u64, 1) << 2);
    cr0 |= @intCast(u64, 1) << 1;
    arch.cr.write(0, cr0);

    var cr4 = arch.cr.read(4);
    cr4 |= @intCast(u64, 3) << 9;
    arch.cr.write(4, cr4);

    writer.init();
    gdt.init();
    interrupt.init();
    lara.main();
    arch.halt();
}
