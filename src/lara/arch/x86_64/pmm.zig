const std = @import("std");
const limine = @import("limine");
const bitmap = @import("../../bitmap.zig");
const math = @import("../../math.zig");
const log = std.log.scoped(.pmm);

var pmm_bitmap: [*]u8 = undefined;
var page_count: u64 = 0;
var last_used_index: u64 = 0;
var usable_pages: u64 = 0;
var used_pages: u64 = 0;
var reserved_pages: u64 = 0;

const higher_half: u64 = 0xffff800000000000;
const page_size: u64 = 0x1000;

export var memmap_request: limine.MemoryMap.Request = .{};

pub const Slab = struct {
    first_free: **anyopaque,
    entry_size: u64,

    const Header = struct { slab: *Slab };

    pub fn init(self: *@This(), entry_size: u64) void {
        self.entry_size = entry_size;
        self.first_free = @intToPtr(**anyopaque, @ptrToInt(alloc_nozero(1)) + higher_half);

        const size = page_size - math.alignUp(@sizeOf(Header), entry_size);
        var slab_ptr = @ptrCast(*Header, self.first_free);
        slab_ptr.slab = self;
        self.first_free = @intToPtr(**anyopaque, @ptrToInt(self.first_free) + math.alignUp(@sizeOf(Header), entry_size));

        var array = @ptrCast([*]*anyopaque, self.first_free);
        const max = size / entry_size - 1;
        const fact = entry_size / @sizeOf(*anyopaque);

        var i: u64 = 0;
        while (i < max) : (i += 1) {
            array[i * fact] = @ptrCast(*anyopaque, &array[(i + 1) * fact]);
        }

        array[max * fact] = undefined;
    }

    pub fn alloc(self: *@This()) *anyopaque {
        if (self.first_free == undefined) {
            self.init(self.entry_size);
        }

        var old_free = self.first_free;
        self.first_free = old_free.*;

        @memset(old_free, 0, self.entry_size);

        return old_free;
    }

    pub fn free(self: *@This(), ptr: *anyopaque) *anyopaque {
        if (ptr == 0)
            return;

        var new_head = &ptr;
        new_head = self.first_free;

        self.first_free = new_head;
    }
};

var slabs: [10]Slab = undefined;

pub fn init() void {
    if (memmap_request.response) |memmap| {
        var highest_address: u64 = 0;
        var entries = memmap.getEntries();

        // Calculate how big should the memory map be.
        for (entries) |entry, i| {
            log.info("Entry {}: base=0x{x}, length=0x{x}, type={s}", .{ i, entry.base, entry.length, @tagName(entry.type) });
            switch (entry.type) {
                .Usable => {
                    usable_pages += math.divRoundup(entry.length, page_size);
                    highest_address = math.max(highest_address, entry.base + entry.length);
                },
                else => reserved_pages += math.divRoundup(entry.length, page_size),
            }
        }

        // Calculate the needed size for the bitmap in bytes and align it to page size.<F11>
        page_count = highest_address / page_size;
        const bitmap_size = math.alignUp(page_count / 8, page_size);

        log.info("Highest address: {x}", .{highest_address});
        log.info("Bitmap size: {} bytes", .{bitmap_size});

        // Find a hole for the bitmap in the memory map
        for (entries) |entry| {
            if (entry.type != .Usable) continue;
            if (entry.length >= bitmap_size) {
                pmm_bitmap = @intToPtr([*]u8, entry.base + higher_half);

                // Initialize the bitmap to 1
                @memset(pmm_bitmap, 0xff, bitmap_size);

                entry.length -= bitmap_size;
                entry.base += bitmap_size;

                break;
            }
        }

        // Populate free bitmap entries according to the memory map.
        for (entries) |entry| {
            if (entry.type != .Usable) continue;

            var i: u64 = 0;
            while (i < entry.length) : (i += page_size)
                bitmap.unset(pmm_bitmap, (entry.base + i) / page_size);
        }

        log.info("Usable memory: {} MB", .{(usable_pages * 4096) / 1024 / 1024});
        log.info("Reserved memory: {} MB", .{(reserved_pages * 4096) / 1024 / 1024});

        slabs[0].init(8);
        slabs[1].init(16);
        slabs[2].init(24);
        slabs[3].init(32);
        slabs[4].init(48);
        slabs[5].init(64);
        slabs[6].init(128);
        slabs[7].init(256);
        slabs[8].init(512);
        slabs[9].init(1024);
    }
}

fn inner_alloc(count: u64, limit: u64) *anyopaque {
    var p: u64 = 0;

    while (last_used_index < limit) {
        if (!bitmap.check(pmm_bitmap, last_used_index)) {
            last_used_index += 1;

            p += 1;
            if (p == count) {
                const page = last_used_index - count;

                var i: u64 = 0;
                while (i < last_used_index) : (i += 1)
                    bitmap.set(pmm_bitmap, i);

                return @intToPtr(*anyopaque, page * page_size);
            }
        } else {
            last_used_index += 1;
            p = 0;
        }
    }

    return undefined;
}

pub fn alloc_nozero(count: u64) *anyopaque {
    const last = last_used_index;
    var ret = inner_alloc(count, page_count);

    if (ret == undefined) {
        last_used_index = 0;
        ret = inner_alloc(count, last);
        //if (ret == undefined) {
        //    @panic("Allocated memory is null");
        //}
    }

    used_pages += count;
    return ret;
}

pub fn alloc(count: u64) *anyopaque {
    const ret = alloc_nozero(count);
    var ptr = @intToPtr(*anyopaque, ret + higher_half);

    var i = 0;
    while (i < (count * page_size) / 8) : (i += 1)
        ptr[i] = 0;

    return ret;
}

pub fn free(ptr: *void, count: u64) void {
    const page = ptr / page_size;

    var i = 0;
    while (i < page + count) : (i += 1)
        bitmap.unset(pmm_bitmap, i);

    used_pages -= count;
}
