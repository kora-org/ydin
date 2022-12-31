pub fn set(bitmap: [*]u8, bit: u64) void {
    bitmap[bit / 8] |= @intCast(u8, 1) << @intCast(u3, bit % 8);
}

pub fn unset(bitmap: [*]u8, bit: u64) void {
    bitmap[bit / 8] &= ~(@intCast(u8, 1) << @intCast(u3, bit % 8));
}

pub fn check(bitmap: [*]u8, bit: u64) bool {
    return (bitmap[bit / 8] & (@intCast(u8, 1) << @intCast(u3, bit % 8))) != 0;
}
