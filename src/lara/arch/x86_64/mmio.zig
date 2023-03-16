pub fn read(comptime T: type, address: u64) T {
    @fence(.SeqCst);
    return @intToPtr(*volatile T, address).*;
}

pub fn write(comptime T: type, address: u64, value: T) void {
    @fence(.SeqCst);
    @intToPtr(*volatile T, address).* = value;
}
