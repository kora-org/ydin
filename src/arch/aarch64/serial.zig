const std = @import("std");
const dtb = @import("dtb");
const arch = @import("../aarch64.zig");
const utils = @import("../../utils.zig");
const Pl011 = @import("serial/pl011.zig");
const Ns16550 = @import("serial/ns16550.zig");

const Uart = struct {
    address: u64,
    kind: Kind,

    pub const Kind = enum {
        /// "arm,pl011" (QEMU ARM Virt, Raspberry Pi)
        Pl011,
        /// "snps,dw-apb-uart" (ROCKPro64)
        /// "ns16550a" (QEMU RISC-V Virt)
        Ns16550,
    };

    pub fn init() !Uart {
        var traverser: dtb.Traverser = undefined;
        const size = try dtb.totalSize(@as(*anyopaque, @ptrFromInt(arch.device_tree)));
        try traverser.init(@as([*]u8, @ptrFromInt(arch.device_tree))[0..size]);

        var in_node = false;
        var state: struct {
            compatible: ?[]const u8 = null,
            reg: ?u64 = null,
        } = undefined;

        var address_cells: ?u32 = null;
        var size_cells: ?u32 = null;

        var event = try traverser.event();
        while (event != .End) : (event = try traverser.event()) {
            if (!in_node) {
                switch (event) {
                    .BeginNode => |name| {
                        if (std.mem.startsWith(u8, name, "pl011@") or
                            std.mem.startsWith(u8, name, "serial@") or
                            std.mem.startsWith(u8, name, "uart@"))
                        {
                            in_node = true;
                            state = .{};
                        }
                    },
                    .Prop => |prop| {
                        if (std.mem.eql(u8, prop.name, "#address-cells") and address_cells == null) {
                            address_cells = utils.readU32(prop.value);
                        } else if (std.mem.eql(u8, prop.name, "#size-cells") and size_cells == null) {
                            size_cells = utils.readU32(prop.value);
                        }
                    },
                    else => {},
                }
            } else switch (event) {
                .Prop => |prop| {
                    if (std.mem.eql(u8, prop.name, "reg") and address_cells != null and size_cells != null) {
                        state.reg = try utils.firstReg(address_cells.?, prop.value);
                    } else if (std.mem.eql(u8, prop.name, "status")) {
                        if (!std.mem.eql(u8, prop.value, "okay\x00")) {
                            in_node = false;
                        }
                    } else if (std.mem.eql(u8, prop.name, "compatible")) {
                        state.compatible = prop.value;
                    }
                },
                .BeginNode => in_node = false,
                .EndNode => {
                    in_node = false;
                    const reg = state.reg orelse continue;
                    const compatible = state.compatible orelse continue;
                    const kind: Kind = if (std.mem.indexOf(u8, compatible, "arm,pl011\x00") != null)
                        .Pl011
                    else if (std.mem.indexOf(u8, compatible, "snps,dw-apb-uart\x00") != null or
                        std.mem.indexOf(u8, compatible, "ns16550a\x00") != null)
                        .Ns16550
                    else
                        continue;

                    return Uart{
                        .address = reg,
                        .kind = kind,
                    };
                },
                else => {},
            }
        }

        return error.NotFound;
    }
};

pub const SerialImpl = union(enum) {
    pl011: Pl011,
    ns16550: Ns16550,

    pub fn init(self: SerialImpl) void {
        switch (self) {
            inline else => |impl| return impl.init(),
        }
    }

    pub fn write(self: SerialImpl, bytes: []const u8) !usize {
        switch (self) {
            inline else => |impl| return impl.write(bytes),
        }
    }
};

pub fn Serial() !SerialImpl {
    const uart = try Uart.init();
    return switch (uart.kind) {
        .Pl011 => .{ .pl011 = .{ .address = uart.address } },
        .Ns16550 => .{ .ns16550 = .{ .address = uart.address } },
    };
}
