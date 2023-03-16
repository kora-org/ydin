const std = @import("std");
const io = @import("io.zig");

port: u16 = 0x3f8,

const INTERRUPT_OFFSET: u16 = 1;
const FIFO_CONTROL_OFFSET: u16 = 2;
const LINE_CONTROL_OFFSET: u16 = 3;
const MODEM_CONTROL_OFFSET: u16 = 4;
const LINE_STATUS_OFFSET: u16 = 5;

const Self = @This();
pub const Error = error{};

/// Initialize the serial port.
pub fn init(self: Self) void {
    // Disable all interupts.
    io.write(u8, self.port + INTERRUPT_OFFSET, 0x00);

    // Enable DLAB.
    io.write(u8, self.port + LINE_CONTROL_OFFSET, 0x80);

    // Set maximum speed to 115200 baud by configuring DLL
    // and DLM.
    io.write(u8, self.port, 0x01);
    io.write(u8, self.port + INTERRUPT_OFFSET, 0);

    // Disable DLAB and set data word length to 8 bits.
    io.write(u8, self.port + LINE_CONTROL_OFFSET, 0x03);

    // Enable FIFO, clear TX/RX queues, and set a 14-byte
    // interrupt threshold.
    io.write(u8, self.port + FIFO_CONTROL_OFFSET, 0xc7);

    // Mark data terminal ready, signal request to send and
    // enable auxilliary output #2. (used as interrupt line
    // for the CPU)
    io.write(u8, self.port + MODEM_CONTROL_OFFSET, 0x0b);

    // Enable interrupts.
    io.write(u8, self.port + INTERRUPT_OFFSET, 0x01);
}

/// Sends a byte on the serial port.
pub fn writeByte(self: Self, byte: u8) void {
    switch (byte) {
        0x7f => {
            io.write(u8, self.port, 0x7f);
            io.write(u8, self.port, ' ');
            io.write(u8, self.port, 0x7f);
        },
        0x0a => {
            io.write(u8, self.port, 0x0d);
            io.write(u8, self.port, 0x0a);
        },
        else => io.write(u8, self.port, byte),
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
    return io.read(u8, self.port);
}
