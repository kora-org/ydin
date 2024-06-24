const std = @import("std");
const limine = @import("limine");
const arch = @import("../x86_64.zig");
const gdt = @import("gdt.zig");
const interrupt = @import("interrupt.zig");
const framebuffer = @import("../../framebuffer.zig");
const ydin = @import("../../main.zig");
const writer = @import("../../writer.zig");

pub fn start() callconv(.C) void {
    framebuffer.init();
    writer.init();
    gdt.init();
    interrupt.init();
    ydin.main() catch unreachable;
    arch.halt();
}
