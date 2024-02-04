const std = @import("std");
const limine = @import("limine");
const arch = @import("../../aarch64.zig");
const vmm = @import("vmm.zig");
const slab = @import("slab.zig");
const log = std.log.scoped(.pmm);

const Bitmap = struct {
    const Self = @This();

    bits: [*]u8,
    size: usize,

    pub fn set(self: Self, bit: u64) void {
        self.bits[bit / 8] |= @as(u8, 1) << @as(u3, bit % 8);
    }

    pub fn unset(self: Self, bit: u64) void {
        self.bits[bit / 8] &= ~(@as(u8, 1) << @as(u3, bit % 8));
    }

    pub fn check(self: Self, bit: u64) bool {
        return (self.bits[bit / 8] & (@as(u8, 1) << @as(u3, bit % 8))) != 0;
    }
};

var bitmap: Bitmap = undefined;
var page_count: usize = 0;
var last_used_index: usize = 0;
var used_pages: usize = 0;
var lock = arch.Spinlock{};

pub export var memmap_request: limine.MemoryMap.Request = .{};
pub var memmap_response: limine.MemoryMap.Response = undefined;
pub export var hhdm_request: limine.Hhdm.Request = .{};
pub var hhdm_response: limine.Hhdm.Response = undefined;

pub fn init() void {
    if (memmap_request.response) |memmap| {
        memmap_response = memmap.*;
    }

    if (hhdm_request.response) |hhdm| {
        hhdm_response = hhdm.*;
    }

    var highest_memory: u64 = 0;
    const entries = memmap_response.getEntries();

    // Calculate how big should the memory map be.
    log.debug("Memory map layout:", .{});
    for (entries) |entry| {
        log.debug("  base=0x{x:0>16}, length=0x{x:0>16}, type={s}", .{ entry.base, entry.length, @tagName(entry.type) });
        if (entry.type != .Usable and entry.type != .BootloaderReclaimable)
            continue;

        const top = entry.base + entry.length;
        if (top > highest_memory)
            highest_memory = top;
    }

    // Calculate the needed size for the bitmap in bytes and align it to page size.
    page_count = highest_memory / std.mem.page_size;
    used_pages = page_count;
    bitmap.size = std.mem.alignForward(page_count / 8, std.mem.page_size);

    log.debug("Used pages: {}", .{used_pages});
    log.debug("Bitmap size: {} KB", .{bitmap.size / 1024});

    // Find a hole for the bitmap in the memory map
    for (entries) |entry| {
        if (entry.type != .Usable) continue;
        if (entry.length >= bitmap.size) {
            bitmap.bits = @as([*]u8, @ptrFromInt(entry.base + hhdm_response.offset));

            // Initialize the bitmap to 1
            @memset(bitmap.bits[0..bitmap.size], 0xff);

            entry.length -= bitmap.size;
            entry.base += bitmap.size;

            break;
        }
    }

    // Populate free bitmap entries according to the memory map.
    for (entries) |entry| {
        if (entry.type != .Usable) continue;

        var i: usize = 0;
        while (i < entry.length) : (i += std.mem.page_size)
            bitmap.unset((entry.base + i) / std.mem.page_size);
    }

    slab.init();
}

fn inner_alloc(count: usize, limit: usize) ?[*]u8 {
    var p: usize = 0;
    while (last_used_index < limit) {
        if (!bitmap.check(last_used_index)) {
            last_used_index += 1;
            p += 1;

            if (p == count) {
                const page = last_used_index - count;

                var i: usize = 0;
                while (i < last_used_index) : (i += 1)
                    bitmap.set(i);

                return @as([*]u8, @ptrFromInt(page * std.mem.page_size));
            }
        } else {
            last_used_index += 1;
            p = 0;
        }
    }

    return null;
}

pub fn allocNz(count: usize) ?[*]u8 {
    lock.lock();
    defer lock.unlock();

    const last = last_used_index;
    var ret = inner_alloc(count, page_count);

    if (ret == null) {
        last_used_index = 0;
        ret = inner_alloc(count, last);
        if (ret == null) {
            @panic("Allocated memory is null");
        }
    }

    used_pages += count;
    return ret;
}

pub fn alloc(count: usize) ?[*]u8 {
    const ret = allocNz(count);
    var ptr = @as([*]u8, @ptrFromInt(@intFromPtr(ret.?) + hhdm_response.offset));

    var i: usize = 0;
    while (i < (count * std.mem.page_size) / 8) : (i += 1)
        ptr[i] = 0;

    return ret;
}

pub fn free(buf: ?[*]u8, count: usize) void {
    lock.lock();
    defer lock.unlock();

    const page = @intFromPtr(buf.?) / std.mem.page_size;

    var i: usize = 0;
    while (i < page + count) : (i += 1)
        bitmap.unset(i);

    used_pages -= count;
}
