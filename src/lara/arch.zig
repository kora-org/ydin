const builtin = @import("builtin");

pub usingnamespace switch (builtin.cpu.arch) {
    .x86_64 => @import("arch/x86_64.zig"),
    .aarch64 => @import("arch/aarch64.zig"),
    else => unreachable,
};
