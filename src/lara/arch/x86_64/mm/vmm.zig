const std = @import("std");
const limine = @import("limine");
const pmm = @import("pmm.zig");
const slab = @import("slab.zig");
const log = std.log.scoped(.vmm);

pub export var kernel_address_request: limine.KernelAddress.Request = .{};

pub const CacheMode = enum(u4) {
    Uncached,
    WriteCombining,
    WriteProtect,
    WriteBack,
};

pub const PageFlags = packed struct {
    read: bool = false,
    write: bool = false,
    exec: bool = false,
    user: bool = false,

    cache_type: CacheMode = .WriteBack,
    _padding: u24 = 0,
};

var pagemap = Pagemap{};

pub fn init() void {
    pagemap.root = @ptrToInt(pmm.alloc(1));

    var page_flags = PageFlags{
        .read = true,
        .write = true,
        .exec = true,
    };

    if (kernel_address_request.response) |kernel_address| {
        var pbase: usize = kernel_address.physical_base;
        var vbase: usize = kernel_address.virtual_base;

        var i: usize = 0;
        while (i < (0x400 * 0x1000)) : (i += 0x1000)
            pagemap.mapPage(page_flags, vbase + i, pbase + i, false);

        i = 0;
        page_flags.exec = false;
        while (i < @intCast(usize, (0x800 * 0x200000))) : (i += 0x200000)
            pagemap.mapPage(page_flags, i + pmm.hhdm_response.offset, i, true);
    }

    // them map everything else
    for (pmm.memmap_response.getEntries()) |ent| {
        if (ent.base + ent.length < @intCast(usize, (0x800 * 0x200000))) {
            continue;
        }

        var base: usize = std.mem.alignBackward(ent.base, 0x200000);
        var i: usize = 0;

        while (i < std.mem.alignForward(ent.length, 0x200000)) : (i += 0x200000)
            pagemap.mapPage(page_flags, (base + i) + pmm.hhdm_response.offset, base + i, true);
    }

    pagemap.load();
}

pub const Pagemap = struct {
    const Self = @This();

    root: u64 = undefined,

    pub fn load(self: *Self) void {
        loadSpace(self.root);
    }

    pub fn save(self: *Self) void {
        self.root = saveSpace();
    }

    pub fn mapPage(self: *Self, flags: PageFlags, virt: u64, phys: u64, huge: bool) void {
        var root: ?[*]u64 = @intToPtr([*]u64, @intCast(usize, self.root + pmm.hhdm_response.offset));

        var indices: [4]u64 = [_]u64{
            genIndex(virt, 39), genIndex(virt, 30),
            genIndex(virt, 21), genIndex(virt, 12),
        };

        // perform translation to pte
        root = getNextLevel(root.?, indices[0], true);
        if (root == null) return;

        root = getNextLevel(root.?, indices[1], true);
        if (root == null) return;

        if (huge)
            root.?[indices[2]] = createPte(flags, phys, true)
        else {
            root = getNextLevel(root.?, indices[2], true);
            root.?[indices[3]] = createPte(flags, phys, false);
        }
    }

    pub fn unmapPage(self: *Self, virt: u64) void {
        var root: ?[*]u64 = @intToPtr([*]u64, self.root + pmm.hhdm_response.offset);

        var indices: [4]u64 = [_]u64{
            genIndex(virt, 39), genIndex(virt, 30),
            genIndex(virt, 21), genIndex(virt, 12),
        };

        // perform translation to pte
        root = getNextLevel(root.?, indices[0], false);
        if (root == null) return;

        root = getNextLevel(root.?, indices[1], false);
        if (root == null) return;

        if ((root.?[indices[2]] & (1 << 7)) != 0)
            root.?[indices[2]] &= ~@intCast(u64, 1)
        else if (getNextLevel(root.?, indices[2], false)) |final_root|
            final_root[indices[3]] &= ~@intCast(u64, 1);

        invalidatePage(virt);
    }
};

inline fn genIndex(virt: u64, comptime shift: usize) u64 {
    return ((virt & (0x1FF << shift)) >> shift);
}

fn getNextLevel(level: [*]u64, index: usize, create: bool) ?[*]u64 {
    if ((level[index] & 1) == 0) {
        if (!create) return null;

        if (pmm.alloc(1)) |table_ptr| {
            level[index] = @ptrToInt(table_ptr);
            level[index] |= 0b111;
        } else {
            return null;
        }
    }

    return @intToPtr([*]u64, (level[index] & ~@intCast(u64, 0x1ff)) + pmm.hhdm_response.offset);
}

fn createPte(flags: PageFlags, phys_ptr: u64, huge: bool) u64 {
    var result: u64 = 1; // pages have to be readable to be present
    var pat_bit: u64 = blk: {
        if (huge)
            break :blk (1 << 12)
        else
            break :blk (1 << 7);
    };

    if (flags.write) result |= (1 << 1);
    if (!(flags.exec)) result |= (1 << 63);
    if (flags.user) result |= (1 << 2);
    if (huge) result |= (1 << 7);

    switch (flags.cache_type) {
        .Uncached => {
            result |= (1 << 4) | (1 << 3);
            result &= ~pat_bit;
        },
        .WriteCombining => result |= pat_bit | (1 << 4) | (1 << 3),
        .WriteProtect => {
            result |= pat_bit | (1 << 4);
            result &= ~@intCast(u64, (1 << 3));
        },
        else => {},
    }

    result |= phys_ptr;
    return result;
}

pub inline fn invalidatePage(addr: u64) void {
    asm volatile ("invlpg (%[virt])"
        :
        : [virt] "r" (addr),
        : "memory"
    );
}

pub inline fn loadSpace(ptr: usize) void {
    asm volatile ("mov %[root], %%cr3"
        :
        : [root] "r" (ptr),
        : "memory"
    );
}
pub inline fn saveSpace() usize {
    return asm volatile ("mov %%cr3, %[old_cr3]"
        : [old_cr3] "=r" (-> u64),
        :
        : "memory"
    );
}
