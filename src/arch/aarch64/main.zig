const std = @import("std");
const limine = @import("limine");
const arch = @import("../aarch64.zig");
const writer = @import("../../writer.zig");
const lara = @import("../../main.zig");

pub export var dtb_request: limine.DeviceTree.Request = .{};
pub fn start() callconv(.C) void {
    if (dtb_request.response) |dtb|
        arch.device_tree = dtb.address;

    writer.init();
    lara.main() catch unreachable;
    arch.halt();
}
