const std = @import("std");
const mmio = @import("../mmio.zig");
const pmm = @import("../mm/pmm.zig");
const arch = @import("../../x86_64.zig");

pub const Lapic = extern struct {
    id: u8,
    length: u8,
    processor_id: u8,
    apic_id: u8,
    flags: u32,
};

pub const Registers = enum(u32) {
    LapicId = 0x20,
    EndOfInterrupt = 0xb0,
    Spurious = 0xf0,
    LvtCmci = 0x2f0,
    InterruptCommandReg0 = 0x300,
    InterruptCommandReg1 = 0x310,
    LvtTimer = 0x320,
    TimerInitialCount = 0x380,
    TimerCurrentCount = 0x390,
    TimerDivisor = 0x3e0,
};

pub fn read(register: Registers) u32 {
    return mmio.read(u32, 0xfee00000 + pmm.hhdm_response.offset + @intFromEnum(register));
}

pub fn write(register: Registers, value: u32) void {
    mmio.write(u32, 0xfee00000 + pmm.hhdm_response.offset + @intFromEnum(register), value);
}

pub fn init() void {
    std.debug.assert((arch.rdmsr(0x1b) & 0xfffff000) == 0xfee00000);

    calibrateTimer();
    write(.Spurious, read(.Spurious) | (1 << 8) | 0xff);
}

pub fn eoi() void {
    write(.EndOfInterrupt, 0);
}

pub fn calibrateTimer() void {}

pub fn stopTimer() void {
    write(.TimerInitialCount, 0);
    write(.LvtTimer, 1 << 16);
}

pub fn oneshot() void {}
