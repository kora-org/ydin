const std = @import("std");

pub const Gdt = packed struct {
    pub const Pointer = packed struct {
        size: u16,
        offset: u64,
    };

    pub const Entry = packed struct {
        limit: u16,
        base_low: u16,
        base_mid: u8,
        access: u8,
        granularity: u8,
        base_high: u8,
    };

    null: Entry,
    _16bit_code: Entry,
    _16bit_data: Entry,
    _32bit_code: Entry,
    _32bit_data: Entry,
    _64bit_code: Entry,
    _64bit_data: Entry,
    user_data: Entry,
    user_code: Entry,
    tss: Tss.Entry,
};

pub const Tss = packed struct {
    pub const Entry = packed struct {
        limit: u16,
        base_low: u16,
        base_mid: u8,
        flags: u16,
        base_high: u8,
        base_upper: u32,
        _reserved: u32,
    };

    _reserved0: u32,
    rsp: [3]u64,
    _reserved1: u64,
    ist: [7]u64,
    _reserved2: u64,
    _reserved3: u16,
    iopb_offset: u16,
};

const gdt = Gdt{
    .{ 0, 0, 0, 0, 0, 0 }, // null
    .{ 0xffff, 0, 0, 0x9a, 0x80, 0 }, // 16-bit code
    .{ 0xffff, 0, 0, 0x92, 0x80, 0 }, // 16-bit data
    .{ 0xffff, 0, 0, 0x9a, 0xcf, 0 }, // 32-bit code
    .{ 0xffff, 0, 0, 0x92, 0xcf, 0 }, // 32-bit data
    .{ 0, 0, 0, 0x9a, 0xa2, 0 }, // 64-bit code
    .{ 0, 0, 0, 0x92, 0xa0, 0 }, // 64-bit data
    .{ 0, 0, 0, 0xf2, 0, 0 }, // user data
    .{ 0, 0, 0, 0xfa, 0x20, 0 }, // user code
    .{ 0x68, 0, 0, 0x2089, 0, 0, 0 }, // tss
};
const pointer: Gdt.Pointer = undefined;
const tss: Tss = undefined;

pub fn init() void {}
