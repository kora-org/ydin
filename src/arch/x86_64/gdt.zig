const std = @import("std");
const arch = @import("../x86_64.zig");

pub const Gdt = extern struct {
    entries: [9]u64,
    tss: Tss.Entry,

    pub fn flush(gdtr: arch.Descriptor) void {
        const gs_base = arch.rdmsr(0xc0000101);

        asm volatile (
            \\lgdt %[gdtr]
            \\push $0x28
            \\lea 1f(%%rip), %%rax
            \\push %%rax
            \\lretq
            \\1:
            \\mov $0x30, %%eax
            \\mov %%eax, %%ds
            \\mov %%eax, %%es
            \\mov %%eax, %%fs
            \\mov %%eax, %%gs
            \\mov %%eax, %%ss
            :
            : [gdtr] "*p" (&gdtr),
            : "rax", "rcx", "memory"
        );

        arch.wrmsr(0xc0000101, gs_base);
    }
};

pub const Tss = extern struct {
    const Self = @This();

    pub const Entry = packed struct {
        length: u16,
        base_low: u16,
        base_mid: u8,
        flags: u16,
        base_high: u8,
        base_upper: u32,
        _reserved: u32 = 0,
    };

    _reserved0: u32 = 0,
    rsp: [3]u64,
    _reserved1: u64 = 0,
    ist: [7]u64,
    _reserved2: u64 = 0,
    _reserved3: u16 = 0,
    iopb_offset: u16,

    pub fn init(self: *Self) void {
        const addr: u64 = @intFromPtr(self);

        gdt.tss.base_low = @as(u16, @truncate(addr));
        gdt.tss.base_mid = @as(u8, @truncate(addr >> 16));
        gdt.tss.flags = 0b10001001;
        gdt.tss.base_high = @as(u8, @truncate(addr >> 24));
        gdt.tss.base_upper = @as(u32, @truncate(addr >> 32));
    }

    pub fn flush(_: *Self) void {
        asm volatile ("ltr %[tss]"
            :
            : [tss] "r" (@as(u16, 0x48)),
            : "memory"
        );
    }
};

const gdt: Gdt = .{
    .entries = .{
        // null entry
        0x0000000000000000,

        // 16-bit kernel code/data
        0x00009a000000ffff,
        0x000093000000ffff,

        // 32-bit kernel code/data
        0x00cf9a000000ffff,
        0x00cf93000000ffff,

        // 64-bit kernel code/data
        0x00af9b000000ffff,
        0x00af93000000ffff,

        // 64-bit user data/code
        0x00affa000000ffff,
        0x008ff2000000ffff,
    },
    .tss = .{
        .length = 0x68,
        .base_low = 0,
        .base_mid = 0,
        .flags = 0b10001001,
        .base_high = 0,
        .base_upper = 0,
    },
};

pub fn init() void {
    const descriptor = arch.Descriptor{
        .size = @sizeOf(Gdt) - 1,
        .ptr = @intFromPtr(&gdt),
    };

    Gdt.flush(descriptor);
}
