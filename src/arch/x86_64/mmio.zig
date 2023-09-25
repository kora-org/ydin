pub fn read(comptime T: type, address: u64) T {
    @fence(.SeqCst);
    return @as(*volatile T, @ptrFromInt(address)).*;
}

pub fn write(comptime T: type, address: u64, value: T) void {
    @fence(.SeqCst);
    @as(*volatile T, @ptrFromInt(address)).* = value;
}
