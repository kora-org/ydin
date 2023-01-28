const std = @import("std");
const limine = @import("limine");
const vmm = @import("vmm.zig");
const slab = @import("slab.zig");
const bitmap = @import("../../../bitmap.zig");
const log = std.log.scoped(.pmm);

var pmm_bitmap: [*]u8 = undefined;
var page_count: u64 = 0;
var last_used_index: u64 = 0;
var used_pages: u64 = 0;

pub export var memmap_request: limine.MemoryMap.Request = .{};
pub var memmap_response: limine.MemoryMap.Response = undefined;
pub export var hhdm_request: limine.Hhdm.Request = .{};
pub var hhdm_response: limine.Hhdm.Response = undefined;

pub const page_size: u64 = 0x1000;

pub fn init() void {
    if (memmap_request.response) |memmap| {
        memmap_response = memmap.*;
    }

    if (hhdm_request.response) |hhdm| {
        hhdm_response = hhdm.*;
    }

    var highest_memory: u64 = 0;
    var entries = memmap_response.getEntries();

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
    page_count = highest_memory / page_size;
    used_pages = page_count;
    const bitmap_size = std.mem.alignForward(page_count / 8, page_size);

    log.debug("Used pages: {}", .{used_pages});
    log.debug("Bitmap size: {} KB", .{bitmap_size / 1024});

    // Find a hole for the bitmap in the memory map
    for (entries) |entry| {
        if (entry.type != .Usable) continue;
        if (entry.length >= bitmap_size) {
            pmm_bitmap = @intToPtr([*]u8, entry.base + hhdm_response.offset);

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

    slab.init();
}

fn inner_alloc(count: u64, limit: u64) ?[*]u8 {
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

                return @intToPtr([*]u8, page * page_size);
            }
        } else {
            last_used_index += 1;
            p = 0;
        }
    }

    return null;
}

pub fn allocNz(count: u64) ?[*]u8 {
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

pub fn alloc(count: u64) ?[*]u8 {
    const ret = allocNz(count);
    var ptr = @intToPtr([*]u8, @ptrToInt(ret.?) + hhdm_response.offset);

    var i: u64 = 0;
    while (i < (count * page_size) / 8) : (i += 1)
        ptr[i] = 0;

    return ret;
}

pub fn free(buf: ?[*]u8, count: u64) void {
    const page = @ptrToInt(buf.?) / page_size;

    var i: u64 = 0;
    while (i < page + count) : (i += 1)
        bitmap.unset(pmm_bitmap, i);

    used_pages -= count;
}
