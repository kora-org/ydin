const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const arch = @import("arch.zig");
const pmm = @import("mm/pmm.zig");
const slab = @import("mm/slab.zig");
const psf = @import("psf.zig");
const writer = @import("writer.zig");
const uacpi = @import("acpi.zig");
pub const panic = @import("panic.zig").panic;

var log_lock = arch.Spinlock{};
fn logFn(comptime level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    log_lock.lock();
    defer log_lock.unlock();

    const scope_prefix = if (scope == .default) "main" else @tagName(scope);
    const prefix = "\x1b[32m[ydin:" ++ scope_prefix ++ "] " ++ switch (level) {
        .err => "\x1b[31merror",
        .warn => "\x1b[33mwarning",
        .info => "\x1b[36minfo",
        .debug => "\x1b[90mdebug",
    } ++ ": \x1b[0m";
    writer.writer.print(prefix ++ format ++ "\n", args) catch unreachable;
}
pub const std_options = std.Options{ .logFn = logFn };

comptime {
    @export(arch.main.start, .{ .name = "_start", .linkage = .strong });
    _ = uacpi;
}

pub fn main() !void {
    std.log.info("\x1b[94mKora\x1b[0m version {s}", .{build_options.version});
    std.log.info("Compiled with Zig v{}", .{builtin.zig_version});
    std.log.info("All your {s} are belong to us.", .{"codebase"});
    pmm.init();
    arch.vmm.init();
    arch.acpi.init();
    try arch.smp.init();
    //if (arch.acpi.rsdp_request.response) |rsdp|
    //    arch.acpi.rsdp_response = rsdp.*;
    //
    //var params = uacpi.uacpi.uacpi_init_params{
    //    .rsdp = arch.acpi.rsdp_response.address,
    //    .rt_params = .{
    //        .log_level = uacpi.uacpi.UACPI_LOG_INFO,
    //        .flags = 0,
    //    },
    //    .no_acpi_mode = true,
    //};
    //_ = uacpi.uacpi.uacpi_initialize(&params);

    //@panic("test");
}
