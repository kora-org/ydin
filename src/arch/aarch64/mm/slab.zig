const std = @import("std");
const arch = @import("../../aarch64.zig");
const pmm = @import("pmm.zig");
const vmm = @import("vmm.zig");
const math = @import("../../../math.zig");
const Allocator = std.mem.Allocator;

pub const Slab = struct {
    lock: arch.Spinlock,
    first_free: [*]u8,
    entry_size: u64,

    const Header = struct { slab: *Slab };

    pub fn init(self: *Slab, entry_size: u64) void {
        self.entry_size = entry_size;
        self.first_free = @as([*]u8, @ptrFromInt(@intFromPtr(pmm.allocNz(1)) + pmm.hhdm_response.offset));

        const size = std.mem.page_size - math.alignUp(@sizeOf(Header), entry_size);
        var slab_ptr = @as(*Header, @ptrCast(@alignCast(self.first_free)));
        slab_ptr.slab = self;
        self.first_free = @as([*]u8, @ptrFromInt(@intFromPtr(self.first_free) + math.alignUp(@sizeOf(Header), entry_size)));

        var array = @as([*]*u8, @ptrCast(@alignCast(self.first_free)));
        const max = size / entry_size - 1;
        const fact = entry_size / @sizeOf(*u8);

        var i: u64 = 0;
        while (i < max) : (i += 1) {
            array[i * fact] = @as(*u8, @ptrCast(&array[(i + 1) * fact]));
        }

        array[max * fact] = undefined;
    }

    pub fn alloc(self: *Slab) ?[*]u8 {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.first_free == undefined) {
            self.init(self.entry_size);
        }

        var old_free = self.first_free;
        self.first_free = old_free;

        @memset(old_free[0..self.entry_size], 0);

        return old_free;
    }

    pub fn free(self: *Slab, ptr: ?[*]u8) void {
        self.lock.lock();
        defer self.lock.unlock();

        if (ptr == null)
            return;

        var new_head = ptr.?;
        new_head = self.first_free;

        self.first_free = new_head;
    }
};

var slabs: [10]Slab = undefined;

pub fn init() void {
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

const AllocMetadata = struct {
    pages: usize,
    size: usize,
};

fn slabFor(len: usize) *Slab {
    var i: u64 = 0;
    while (i < slabs.len) : (i += 1) {
        var slab = slabs[i];
        if (slab.entry_size >= len)
            return &slab;
    }

    return undefined;
}

pub fn alloc(_: *anyopaque, len: usize, _: u8, _: usize) ?[*]u8 {
    var slab = slabFor(len);
    if (slab != undefined)
        return slab.alloc();

    const page_count = math.divRoundup(len, std.mem.page_size);
    var ret = pmm.alloc(page_count + 1);
    if (ret == null)
        return null;

    ret = @as([*]u8, @ptrFromInt(@intFromPtr(ret.?) + pmm.hhdm_response.offset));
    const metadata = @as(*AllocMetadata, @ptrCast(@alignCast(ret.?)));

    metadata.pages = page_count;
    metadata.size = len;

    return @as([*]u8, @ptrFromInt(@intFromPtr(ret) + std.mem.page_size));
}

pub fn _resize(buf: []u8, new_size: usize) []u8 {
    if (buf.ptr == undefined)
        return alloc(undefined, new_size, 0, 0).?[0..new_size];

    if ((@intFromPtr(buf.ptr) & 0xfff) == 0) {
        var metadata = @as(*AllocMetadata, @ptrFromInt(@intFromPtr(buf.ptr) - std.mem.page_size));
        if (math.divRoundup(metadata.size, std.mem.page_size) == math.divRoundup(new_size, std.mem.page_size)) {
            metadata.size = new_size;
            return buf;
        }

        var new_buf = alloc(undefined, new_size, 0, 0);
        if (new_buf == null)
            return undefined;

        if (metadata.size > new_size)
            @memcpy(new_buf.?[0..new_size], buf.ptr)
        else
            @memcpy(new_buf.?[0..metadata.size], buf.ptr);

        free(undefined, buf, 0, 0);
        if (metadata.size > new_size)
            return new_buf.?[0..new_size]
        else
            return new_buf.?[0..metadata.size];
    }

    const header = @as(*Slab.Header, @ptrFromInt(@intFromPtr(buf.ptr) & ~@as(u16, @intCast(0xfff))));
    var slab = header.slab;

    if (new_size > slab.entry_size) {
        var new_buf = alloc(undefined, new_size, 0, 0);
        if (new_buf == null)
            return undefined;

        @memcpy(new_buf.?[0..slab.entry_size], buf.ptr);
        slab.free(buf.ptr);
        return buf;
    }

    return buf;
}

pub fn resize(_: *anyopaque, buf: []u8, _: u8, new_len: usize, _: usize) bool {
    var new_buf = _resize(buf, new_len);
    if (new_buf.ptr != undefined) {
        @memcpy(new_buf.ptr[0..new_len], buf.ptr);
        return true;
    }

    return false;
}

pub fn free(_: *anyopaque, buf: []u8, _: u8, _: usize) void {
    if (buf.ptr == undefined)
        return;

    if ((@intFromPtr(buf.ptr) & 0xfff) == 0) {
        const metadata = @as(*AllocMetadata, @ptrFromInt(@intFromPtr(buf.ptr) - std.mem.page_size));
        pmm.free(@as([*]u8, @ptrFromInt(@intFromPtr(metadata) - pmm.hhdm_response.offset)), metadata.pages + 1);
        return;
    }

    const header = @as(*Slab.Header, @ptrFromInt(@intFromPtr(buf.ptr) & ~@as(u16, @intCast(0xfff))));
    var slab = header.slab;
    slab.free(buf.ptr);
}

pub var allocator = Allocator{
    .ptr = undefined,
    .vtable = &.{
        .alloc = alloc,
        .resize = resize,
        .free = free,
    },
};
