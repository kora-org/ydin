const builtin = @import("builtin");

pub const pmm = @import("mm/pmm.zig");
pub const slab = @import("mm/slab.zig");
pub const vmm = switch (builtin.cpu.arch) {
    .x86_64 => @import("arch/x86_64/mm/vmm.zig"),
    else => unreachable,
};
