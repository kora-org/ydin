const std = @import("std");
const mmio = @import("../mmio.zig");
const pmm = @import("../mm/pmm.zig");
const arch = @import("../../x86_64.zig");

pub const IoApic = extern struct {
    id: u8,
    length: u8,
    apic_id: u8,
    _reserved: u8,
    address: u32,
    gsi_base: u32,
};
