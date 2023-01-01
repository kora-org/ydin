const std = @import("std");
const limine = @import("limine");
const pmm = @import("pmm.zig");
const vmm = @import("vmm.zig");
const slab = @import("slab.zig");
const log = std.log.scoped(.vmm);

const text_start: []u8 = undefined;
const text_end: []u8 = undefined;
const rodata_start: []u8 = undefined;
const rodata_end: []u8 = undefined;
const data_start: []u8 = undefined;
const data_end: []u8 = undefined;

pub const higher_half: u64 = 0xffff800000000000;

const Pte = struct {
    pub const Flags = enum(u64) {
        Present = 1 << 0,
        ReadWrite = 1 << 1,
        UserSupervisor = 1 << 2,
        WriteThrough = 1 << 3,
        CacheDisabled = 1 << 4,
        Accessed = 1 << 5,
        Dirty = 1 << 6,
        PageAttributeTable = 1 << 7,
        Global = 1 << 8,
        ExecuteDisable = 1 << 63,
    };

    pub const address_mask: u64 = 0x000ffffffffff000;

    pub fn getAddress(value: u64) u64 {
        return value & address_mask;
    }

    pub fn getFlags(value: u64) u64 {
        return value & ~address_mask;
    }
};

const Pagemap = struct {
    top_level: *u64,
};

var pagemap: Pagemap = undefined;

pub fn initPagemap() *Pagemap {
    const top_level: *u64 = @ptrCast(*u64, pmm.alloc(1));

    const p1 = @intToPtr(*u64, @ptrToInt(top_level) + vmm.higher_half);
    const p2 = @intToPtr(*u64, @ptrToInt(pagemap.top_level) + vmm.higher_half);

    var i: u64 = 256;
    while (i < 512) : (i += 1)
        p1[i] = p2[i];

    var _pagemap = @ptrCast(*Pagemap, slab.alloc(@sizeOf(Pagemap)));
    _pagemap.top_level = top_level;

    return _pagemap;
}
