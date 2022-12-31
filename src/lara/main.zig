const std = @import("std");
const builtin = @import("builtin");
const arch = @import("arch.zig");
//const pmm = @import("pmm.zig");
const log = std.log.scoped(.lara);

pub fn main() void {
    log.info("\x1b[94mFaruOS\x1b[0m version 0.1.0-dev", .{});
    log.info("Compiled with Zig v{}", .{builtin.zig_version});
    log.info("All your codebase are belong to us.", .{});
    arch.pmm.init();
    @panic("test");
}
