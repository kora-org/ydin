const std = @import("std");
const arch = @import("arch");
const log = std.log.scoped(.Lara);

pub fn main() void {
    log.debug("Hello {s}!", .{"World"});
}
