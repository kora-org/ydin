const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const arch = @import("arch.zig");
const psf = @import("psf.zig");

pub fn main() !void {
    std.log.info("\x1b[94mKora\x1b[0m version {s}", .{build_options.version});
    std.log.info("Compiled with Zig v{}", .{builtin.zig_version});
    std.log.info("All your {s} are belong to us.", .{"codebase"});
    arch.mm.pmm.init();
    arch.mm.vmm.init();
    arch.acpi.init();
    @panic("test");
}
