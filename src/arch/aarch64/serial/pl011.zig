const std = @import("std");
const mmio = @import("../mmio.zig");

address: u64,

const FLAG_OFFSET = 0x18;
const INTEGER_BAUD_DIVISOR_OFFSET: u64 = 0x24;
const FRACTIONAL_BAUD_DIVISOR_OFFSET: u64 = 0x28;
const LINE_CONTROL_OFFSET: u64 = 0x2c;
const CONTROL_OFFSET: u64 = 0x30;
const INTERRUPT_OFFSET: u64 = 0x44;

const Self = @This();
pub const Error = error{};

/// Initialize the serial port.
pub fn init(self: Self) void {
    // Turn off the UART temporarily
    mmio.write(u32, self.address + CONTROL_OFFSET, 0);

    // Clear all interupts.
    mmio.write(u32, self.address + INTERRUPT_OFFSET, 0x7ff);

    // Set maximum speed to 115200 baud.
    mmio.write(u32, self.address + INTEGER_BAUD_DIVISOR_OFFSET, 0x02);
    mmio.write(u32, self.address + FRACTIONAL_BAUD_DIVISOR_OFFSET, 0x0b);

    // Enable 8N1 and FIFO.
    mmio.write(u32, self.address + LINE_CONTROL_OFFSET, 0x07 << 0x04);

    // Enable interrupts.
    mmio.write(u32, self.address + INTERRUPT_OFFSET, 0x301);
}

/// Sends a byte on the serial port.
pub fn writeByte(self: Self, byte: u8) void {
    switch (byte) {
        0x7f => {
            mmio.write(u32, self.address, 0x7f);
            mmio.write(u32, self.address, ' ');
            mmio.write(u32, self.address, 0x7f);
        },
        0x0a => {
            mmio.write(u32, self.address, 0x0d);
            mmio.write(u32, self.address, 0x0a);
        },
        else => mmio.write(u32, self.address, byte),
    }
}

/// Sends bytes to the serial port.
pub fn write(self: Self, bytes: []const u8) Error!usize {
    for (bytes) |byte|
        writeByte(self, byte);

    return bytes.len;
}

/// Receives a byte on the serial port.
pub fn read(self: Self) u8 {
    return @truncate(mmio.read(u32, self.address));
}
