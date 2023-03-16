const std = @import("std");

pub fn readU32(value: []const u8) u32 {
    return std.mem.bigToNative(u32, @ptrCast(*const u32, @alignCast(@alignOf(u32), value.ptr)).*);
}

pub fn firstReg(address_cells: u32, value: []const u8) !u64 {
    if (value.len % @sizeOf(u32) != 0) {
        return error.BadStructure;
    }
    var big_endian_cells: []const u32 = @ptrCast([*]const u32, @alignCast(@alignOf(u32), value.ptr))[0 .. value.len / @sizeOf(u32)];
    if (address_cells == 1) {
        return std.mem.bigToNative(u32, big_endian_cells[0]);
    } else if (address_cells == 2) {
        return @as(u64, std.mem.bigToNative(u32, big_endian_cells[0])) << 32 | std.mem.bigToNative(u32, big_endian_cells[1]);
    }
    return error.UnsupportedCells;
}