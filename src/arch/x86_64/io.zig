pub inline fn read(comptime T: type, port: u16) T {
    return switch (T) {
        u8 => asm volatile("inb %[port], %[ret]"
            : [ret] "={al}"(-> u8),
            : [port] "N{dx}"(port),
        ),

        u16 => asm volatile("inw %[port], %[ret]"
            : [ret] "={al}"(-> u16),
            : [port] "N{dx}"(port),
        ),

        u32 => asm volatile("inl %[port], %[ret]"
            : [ret] "={eax}"(-> u32),
            : [port] "N{dx}"(port),
        ),

        else => unreachable,
    };
}

pub inline fn write(comptime T: type, port: u16, value: T) void {
    switch (T) {
        u8 => asm volatile("outb %[value], %[port]"
            :
            : [value] "{al}"(value),
              [port] "N{dx}"(port),
        ),

        u16 => asm volatile("outw %[value], %[port]"
            :
            : [value] "{al}"(value),
              [port] "N{dx}"(port),
        ),

        u32 => asm volatile("outl %[value], %[port]"
            :
            : [value] "{eax}"(value),
              [port] "N{dx}"(port),
        ),

        else => unreachable,
    }
}
