const std = @import("std");
const mmio = @import("../mmio.zig");

// Same as x86's serial implementation except using MMIO instead of
// x86's PMIO.

address: u64,

const INTERRUPT_OFFSET: u64 = 1;
const FIFO_CONTROL_OFFSET: u64 = 2;
const LINE_CONTROL_OFFSET: u64 = 3;
const MODEM_CONTROL_OFFSET: u64 = 4;
const LINE_STATUS_OFFSET: u64 = 5;

const Self = @This();
pub const Error = error{};

/// Initialize the serial port.
pub fn init(self: Self) void {
    // Disable all interupts.
    mmio.write(u8, self.address + INTERRUPT_OFFSET, 0x00);

    // Enable DLAB.
    mmio.write(u8, self.address + LINE_CONTROL_OFFSET, 0x80);

    // Set maximum speed to 115200 baud by configuring DLL
    // and DLM.
    mmio.write(u8, self.address, 0x01);
    mmio.write(u8, self.address + INTERRUPT_OFFSET, 0);

    // Disable DLAB and set data word length to 8 bits.
    mmio.write(u8, self.address + LINE_CONTROL_OFFSET, 0x03);

    // Enable FIFO, clear TX/RX queues, and set a 14-byte
    // interrupt threshold.
    mmio.write(u8, self.address + FIFO_CONTROL_OFFSET, 0xc7);

    // Mark data terminal ready, signal request to send and
    // enable auxilliary output #2. (used as interrupt line
    // for the CPU)
    mmio.write(u8, self.address + MODEM_CONTROL_OFFSET, 0x0b);

    // Enable interrupts.
    mmio.write(u8, self.address + INTERRUPT_OFFSET, 0x01);
}

/// Sends a byte on the serial port.
pub fn writeByte(self: Self, byte: u8) void {
    switch (byte) {
        0x7f => {
            mmio.write(u8, self.address, 0x7f);
            mmio.write(u8, self.address, ' ');
            mmio.write(u8, self.address, 0x7f);
        },
        0x0a => {
            mmio.write(u8, self.address, 0x0d);
            mmio.write(u8, self.address, 0x0a);
        },
        else => mmio.write(u8, self.address, byte),
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
    return mmio.read(u8, self.address);
}
