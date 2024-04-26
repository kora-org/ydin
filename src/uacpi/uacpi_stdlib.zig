const std = @import("std");

pub export fn uacpi_memcpy(dest: [*]u8, src: [*]u8, size: usize) callconv(.C) [*]u8 {
    @memcpy(dest[0..size], src[0..size]);
    return dest;
}

pub export fn uacpi_memset(dest: [*c]u8, value: c_int, size: usize) callconv(.C) [*c]u8 {
    @memset(dest[0..size], @intCast(value));
    return dest;
}

pub export fn uacpi_memcmp(src1: [*c]const u8, src2: [*c]const u8, size: usize) callconv(.C) c_int {
    return @intFromBool(std.mem.eql(u8, src1[0..size], src2[0..size]));
}

pub export fn uacpi_strncmp(src1: [*c]const u8, src2: [*c]const u8, length: usize) callconv(.C) c_int {
    return @intFromBool(std.mem.eql(u8, src1[0..length], src2[0..length]));
}

pub export fn uacpi_strcmp(src1: [*c]const u8, src2: [*c]const u8) callconv(.C) c_int {
    return @intFromBool(std.mem.eql(u8, std.mem.span(src1), std.mem.span(src2)));
}

pub export fn uacpi_memmove(dest: [*]u8, src: [*]u8, size: usize) callconv(.C) [*]u8 {
    @memcpy(dest, src[0..size]);
    @memset(src[0..size], 0);
    return dest;
}

pub export fn uacpi_strnlen(src: [*c]const u8, size: usize) callconv(.C) usize {
    return src[0..size].len;
}

pub export fn uacpi_strlen(src: [*c]const u8) callconv(.C) usize {
    return std.mem.span(src).len;
}
