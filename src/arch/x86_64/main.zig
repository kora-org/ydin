const std = @import("std");
const limine = @import("limine");
const arch = @import("../x86_64.zig");
const gdt = @import("gdt.zig");
const interrupt = @import("interrupt.zig");
const framebuffer = @import("../../framebuffer.zig");
const ydin = @import("../../main.zig");
const writer = @import("../../writer.zig");

pub fn start() callconv(.C) void {
    // Initialize x87 FPU
    asm volatile ("fninit");

    // Enable SSE
    var cr0 = arch.cr.read(0);
    cr0 &= ~(@as(u64, 1) << 2);
    cr0 |= @as(u64, 1) << 1;
    arch.cr.write(0, cr0);

    var cr4 = arch.cr.read(4);
    cr4 |= @as(u64, 3) << 9;
    arch.cr.write(4, cr4);

    framebuffer.init();
    writer.init();
    gdt.init();
    interrupt.init();
    ydin.main() catch unreachable;
    arch.halt();
}
