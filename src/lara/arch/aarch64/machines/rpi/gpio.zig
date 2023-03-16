const mmio = @import("mmio.zig");

pub const Registers = enum(u64) {
    GPFSEL0 = mmio.getMmioBase() + 0x200000,
    GPFSEL1 = mmio.getMmioBase() + 0x200004,
    GPFSEL2 = mmio.getMmioBase() + 0x200008,
    GPFSEL3 = mmio.getMmioBase() + 0x20000c,
    GPFSEL4 = mmio.getMmioBase() + 0x200010,
    GPFSEL5 = mmio.getMmioBase() + 0x200014,
    GPSET0 = mmio.getMmioBase() + 0x20001c,
    GPSET1 = mmio.getMmioBase() + 0x200020,
    GPCLR0 = mmio.getMmioBase() + 0x200028,
    GPCLR1 = mmio.getMmioBase() + 0x20002c,
    GPLEV0 = mmio.getMmioBase() + 0x200034,
    GPLEV1 = mmio.getMmioBase() + 0x200038,
    GPEDS0 = mmio.getMmioBase() + 0x200040,
    GPEDS1 = mmio.getMmioBase() + 0x200044,
    GPREN0 = mmio.getMmioBase() + 0x20004c,
    GPREN1 = mmio.getMmioBase() + 0x200050,
    GPFEN0 = mmio.getMmioBase() + 0x200058,
    GPFEN1 = mmio.getMmioBase() + 0x20005c,
    GPHEN0 = mmio.getMmioBase() + 0x200064,
    GPHEN1 = mmio.getMmioBase() + 0x200068,
    GPLEN0 = mmio.getMmioBase() + 0x200070,
    GPLEN1 = mmio.getMmioBase() + 0x200074,
    GPAREN0 = mmio.getMmioBase() + 0x20007c,
    GPAREN1 = mmio.getMmioBase() + 0x200080,
    GPAFEN0 = mmio.getMmioBase() + 0x200088,
    GPAFEN1 = mmio.getMmioBase() + 0x20008c,
    GPPUPPDN0 = mmio.getMmioBase() + 0x2000e4,
    GPPUPPDN1 = mmio.getMmioBase() + 0x2000e8,
    GPPUPPDN2 = mmio.getMmioBase() + 0x2000ec,
    GPPUPPDN3 = mmio.getMmioBase() + 0x2000f0,
};

pub const AlternateFunctions = enum(u32) {
    Alt0 = 4,
    Alt1 = 5,
    Alt2 = 6,
    Alt3 = 7,
    Alt4 = 3,
    Alt5 = 2,
};

pub const Pull = enum(u32) {
    None,
    Down, // Are down and up the right way around?
    Up,
};

pub fn call(pin_number: usize, value: u32, base: Registers, field_size: usize) void {
    const field_mask: usize = (1 << field_size) - 1;
    const num_fields: usize = 32 / field_size;
    const register: u64 = @enumToInt(base) + ((pin_number / num_fields) * 4);
    const shift: usize = (pin_number % num_fields) * field_size;

    var current_value = mmio.read(register);
    current_value &= ~(field_mask << shift);
    current_value |= value << shift;
    mmio.write(register, current_value);
}

pub fn set(pin_number: usize, value: u32) void {
    call(pin_number, value, .GPSET0, 1);
}

pub fn clear(pin_number: usize, value: u32) void {
    call(pin_number, value, .GPCLR0, 1);
}

pub fn pull(pin_number: usize, value: Pull) void {
    call(pin_number, @enumToInt(value), .GPPUPPDN0, 2);
}

pub fn function(pin_number: usize, value: u32) void {
    call(pin_number, value, .GPFSEL0, 3);
}

pub fn useAlternateFunction(pin_number: usize, alt_function: AlternateFunctions) void {
    pull(pin_number, .None);
    function(pin_number, @enumToInt(alt_function));
}
