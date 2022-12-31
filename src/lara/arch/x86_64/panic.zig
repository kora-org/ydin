const std = @import("std");
const arch = @import("../x86_64.zig");

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    _panic(message, return_address orelse @returnAddress(), @frameAddress());
}

fn _panic(message: []const u8, start_address: usize, frame_pointer: usize) noreturn {
    std.log.err("Kernel panic: {s}", .{message});
    dumpStackTrace(start_address, frame_pointer);
    std.log.err("System halted.", .{});
    arch.halt();

    unreachable;
}

fn dumpStackTrace(start_address: usize, frame_pointer: usize) void {
    var stack_iterator = std.debug.StackIterator.init(start_address, frame_pointer);
    std.log.err("Stack trace:", .{});
    var i: u64 = 0;
    while (stack_iterator.next()) |return_address| : (i += 1) {
        if (return_address != 0) {
            std.log.err("{}: 0x{x}", .{ i, return_address });
        }
    }
}
