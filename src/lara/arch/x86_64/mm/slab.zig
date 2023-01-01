const std = @import("std");
const pmm = @import("pmm.zig");
const vmm = @import("vmm.zig");
const math = @import("../../../math.zig");

pub const Slab = struct {
    first_free: **anyopaque,
    entry_size: u64,

    const Header = struct { slab: *Slab };

    pub fn init(self: *@This(), entry_size: u64) void {
        self.entry_size = entry_size;
        self.first_free = @intToPtr(**anyopaque, @ptrToInt(pmm.alloc_nozero(1)) + vmm.higher_half);

        const size = pmm.page_size - math.alignUp(@sizeOf(Header), entry_size);
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

fn slabFor(size: usize) Slab {
    for (slabs) |slab|
        if (slab.entry_size >= size)
            return &slab;

    return undefined;
}

pub fn alloc(size: usize) *anyopaque {
    var slab = slabFor(size);
    if (slab != undefined)
        return slab.alloc();

    const page_count = math.divRoundup(size, pmm.page_size);
    var ret = pmm.alloc(page_count + 1);
    if (ret == undefined)
        return undefined;

    ret = @intToPtr(*anyopaque, @ptrToInt(ret) + vmm.higher_half);
    const metadata = @ptrCast(*AllocMetadata, ret);

    metadata.pages = page_count;
    metadata.size = size;

    return @intToPtr(*anyopaque, @ptrToInt(ret) + pmm.page_size);
}

pub fn realloc(ptr: *anyopaque, new_size: usize) *anyopaque {
    if (ptr == undefined)
        return alloc(new_size);

    if ((@ptrToInt(ptr) & 0xfff) == 0) {
        var metadata = @ptrCast(*AllocMetadata, @intToPtr(*anyopaque, @ptrToInt(ptr) - pmm.page_size));
        if (math.divRoundup(metadata.size, pmm.page_size) == math.divRoundup(new_size, pmm.page_size)) {
            metadata.size = new_size;
            return ptr;
        }

        var new_ptr = alloc(new_size);
        if (new_ptr == undefined)
            return undefined;

        if (metadata.size > new_size)
            @memcpy(new_ptr, ptr, new_size)
        else
            @memcpy(new_ptr, ptr, metadata.size);

        free(ptr);
        return new_ptr;
    }

    var header = @intToPtr(*Slab.Header, @ptrToInt(ptr) & ~0xfff);
    var slab = header.slab;

    if (new_size > slab.entry_size) {
        var new_ptr = alloc(new_size);
        if (new_ptr == undefined)
            return undefined;

        @memcpy(new_ptr, ptr, slab.entry_size);
        slab.free(ptr);
        return ptr;
    }

    return ptr;
}

pub fn free(ptr: *anyopaque) void {
    if (ptr == undefined)
        return;

    if ((@ptrToInt(ptr) & 0xfff) == 0) {
        var metadata = @ptrCast(*AllocMetadata, @intToPtr(*anyopaque, @ptrToInt(ptr) - pmm.page_size));
        pmm.free(@intToPtr(*anyopaque, @ptrToInt(metadata) - vmm.higher_half), metadata.pages + 1);
        return;
    }

    var header = @intToPtr(*Slab.Header, @ptrToInt(ptr) & ~0xfff);
    var slab = header.slab;
    slab.free(ptr);
}
