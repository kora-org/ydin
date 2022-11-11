pub const Serial = @This();

const std = @import("std");
const io = @import("io.zig");

/// COM port, defaults to COM1
port: u16 = 0x3f8,
data: u16 = port,
interrupt: u16 = port + 1,
fifo_ctrl: u16 = port + 2,
line_ctrl: u16 = port + 3,
modem_ctrl: u16 = port + 4,
line_status: u16 = port + 5,

pub const Error = error{};
const Self = @This();

/// Initialize the serial port
pub fn init(self: Self) void {
    // Disable all interupts
    io.write(u8, self.interrupt, 0x00);

    // Enable DLAB
    io.write(u8, self.line_ctrl, 0x80);

    // Set maximum speed to 38400 bps by configuring DLL and DLM
    io.write(u8, self.data, 0x03);
    io.write(u8, self.interrupt, 0x00);

    // Disable DLAB and set data word length to 8 bits
    io.write(u8, self.line_ctrl, 0x03);

    // Enable FIFO, clear TX/RX queues, and set a 14-byte 
    // interrupt threshold
    io.write(u8, self.fifo_ctrl, 0xC7);

    // Mark data terminal ready, signal request to send
    // and enable auxilliary output #2 (used as interrupt line
    // for the CPU)
    io.write(u8, self.modem_ctrl, 0x0B);

    // Enable interrupts
    io.write(u8, self.interrupt, 0x01);
}

/// Sends a byte on the serial port
pub fn writeByte(self: Self, byte: u8) void {
    _ = self;

    switch (byte) {
        8 | 0x7F => {
            io.write(u8, data, 8);
            io.write(u8, data, ' ');
            io.write(u8, data, 8);
        },
        else => io.write(u8, data, byte),
    }
}

/// Sends bytes to the serial port
pub fn write(self: Self, bytes: []const u8) Error!usize {
    for (bytes) |byte| {
        writeByte(self, byte);
    }

    return bytes.len;
}

/// Receives a byte on the serial port
pub fn read(self: Self) u8 {
    _ = self;

    return io.read(u8, data);
}
