pub fn read(comptime T: type, address: u64) T {
    @fence(.seq_cst);
    return @as(*volatile T, @ptrFromInt(address)).*;
}

pub fn write(comptime T: type, address: u64, value: T) void {
    @fence(.seq_cst);
    @as(*volatile T, @ptrFromInt(address)).* = value;
}
