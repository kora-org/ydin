const std = @import("std");
const acpi = @import("../acpi.zig");
const mmio = @import("../../../mmio.zig");
const pmm = @import("../../../mm/pmm.zig");
const arch = @import("../../x86_64.zig");

pub const Redirect = packed struct(u64) {
    interrupt_vector: u8 = 0,
    delivery_mode: DeliveryMode = .Fixed,
    destination_mode: DestinationMode = .Physical,
    delivery_status: bool = false,
    interrupt_pin: InterruptPinPolarity = .High,
    remote_irr: bool = false,
    trigger_mode: bool = false,
    interrupt_mask: bool = false,
    reserved: u39 = 0,
    destination: u8 = 0,

    const InterruptPinPolarity = enum(u1) {
        High = 0,
        Low = 1,
    };

    const DestinationMode = enum(u1) {
        Physical = 0,
        Logical = 1,
    };

    const DeliveryMode = enum(u3) {
        Fixed = 0b000,
        LowestPriority = 0b001,
        SystemManagementInterrupt = 0b010,
        NonMaskableInterrupt = 0b100,
        Init = 0b101,
        ExtInt = 0b111,
    };
};

pub const IoApic = extern struct {
    id: u8,
    _reserved: u8,
    address: u32,
    gsi_base: u32,

    pub fn read(self: *align(1) IoApic, reg: u32) void {
        const base: u64 = self.ioapic_addr + pmm.hhdm_response.offset;
        @as(*volatile u32, @ptrFromInt(base)).* = reg;
        return @as(*volatile u32, @ptrFromInt(base + 16)).*;
    }

    pub fn write(self: *align(1) IoApic, reg: u32, value: u32) void {
        const base: u64 = self.address + pmm.hhdm_response.offset;
        @as(*volatile u32, @ptrFromInt(base)).* = reg;
        @as(*volatile u32, @ptrFromInt(base + 16)).* = value;
    }

    pub fn redirect_gsi(self: *align(1) IoApic, lapic_id: u32, interrupt_number: u8, gsi: u32, flags: u16) void {
        var redirect = Redirect{ .interrupt_vector = interrupt_number };
        if ((flags & (1 << 1)) == (1 << 1)) redirect.interrupt_pin = .Low;
        if ((flags & (1 << 3)) == (1 << 3)) redirect.trigger_mode = true;
        redirect.destination = @intCast(lapic_id);

        const redirect_table = (gsi - self.gsi_base) * 2 + 16;
        self.write(redirect_table, @as(u32, @truncate(@as(u64, @bitCast(redirect)))));
        self.write(redirect_table + 1, @as(u32, @truncate(@as(u64, @bitCast(redirect)) >> 32)));
    }

    pub fn redirect_irq(self: *align(1) IoApic, lapic_id: u32, interrupt_number: u8, irq: u8) void {
        if (acpi.madt.?.get_iso(irq)) |iso|
            self.redirect_gsi(lapic_id, interrupt_number, iso.gsi, iso.flags)
        else
            self.redirect_gsi(lapic_id, interrupt_number, irq, 0);
    }

    pub fn init(self: *align(1) IoApic) void {
        for (0..16) |i|
            self.redirect_irq(0, @as(u8, @intCast(i)) + 32, @as(u8, @intCast(i)));
    }
};
