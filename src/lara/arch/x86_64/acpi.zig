const std = @import("std");
const limine = @import("limine");
const pmm = @import("mm/pmm.zig");
const log = std.log.scoped(.acpi);

pub const GenericAddress = packed struct {
    base_type: u8,
    bit_width: u8,
    bit_offset: u8,
    access_size: u8,
    base: u64,

    fn read(self: GenericAddress, comptime T: type) T {
        if (self.base_type == 0) { // MMIO
            return @intToPtr(*volatile T, self.base).*;
        } else {
            return switch (T) {
                u8 => asm volatile ("inb %[port], %[result]"
                    : [result] "={al}" (-> T),
                    : [port] "N{dx}" (@truncate(u16, self.base)),
                ),
                u16 => asm volatile ("inw %[port], %[result]"
                    : [result] "={ax}" (-> T),
                    : [port] "N{dx}" (@truncate(u16, self.base)),
                ),
                u32 => asm volatile ("inl %[port], %[result]"
                    : [result] "={eax}" (-> T),
                    : [port] "N{dx}" (@truncate(u16, self.base)),
                ),
                else => @compileError("unsupported type for PIO read: " ++ @typeName(T)),
            };
        }
    }
};

pub const Header = extern struct {
    signature: [4]u8 align(1),
    length: u32 align(1),
    revision: u8 align(1),
    checksum: u8 align(1),
    oem: [6]u8 align(1),
    oem_table: [8]u8 align(1),
    oem_revision: u32 align(1),
    creator_id: u32 align(1),
    creator_revision: u32 align(1),

    fn getContents(self: *Header) []const u8 {
        return @ptrCast([*]const u8, self)[0..self.length][@sizeOf(Header)..];
    }
};

pub const Xsdp = extern struct {
    signature: [8]u8,
    checksum: u8,
    oem: [6]u8,
    revision: u8,
    rsdt: u32,
    length: u32,
    xsdt: u64,
    ext_checksum: u8,
};

pub const Fadt = packed struct {
    firmware_control: u32,
    dsdt: u32,
    reserved: u8,
    profile: u8,
    sci_irq: u16,
    smi_command_port: u32,
    acpi_enable: u8,
    acpi_disable: u8,
    s4bios_req: u8,
    pstate_control: u8,
    pm1a_event_blk: u32,
    pm1b_event_blk: u32,
    pm1a_control_blk: u32,
    pm1b_control_blk: u32,
    pm2_control_blk: u32,
    pm_timer_blk: u32,
    gpe0_blk: u32,
    gpe1_blk: u32,
    pm1_event_length: u8,
    pm1_control_length: u8,
    pm2_control_length: u8,
    pm_timer_length: u8,
    gpe0_length: u8,
    gpe1_length: u8,
    gpe1_base: u8,
    cstate_control: u8,
    worst_c2_latency: u16,
    worst_c3_latency: u16,
    flush_size: u16,
    flush_stride: u16,
    duty_offset: u8,
    duty_width: u8,
    day_alarm: u8,
    month_alarm: u8,
    century: u8,
    iapc_boot_flags: u16,
    reserved2: u8,
    flags: u32,
    reset_register: GenericAddress,
    reset_command: u8,
    arm_boot_flags: u16,
    minor_version: u8,
    x_firmware_control: u64,
    x_dsdt: u64,
    x_pm1a_event_blk: GenericAddress,
    x_pm1b_event_blk: GenericAddress,
    x_pm1a_control_blk: GenericAddress,
    x_pm1b_control_blk: GenericAddress,
    x_pm2_control_blk: GenericAddress,
    x_pm_timer_blk: GenericAddress,
    x_gpe0_blk: GenericAddress,
    x_gpe1_blk: GenericAddress,
};

pub export var rsdp_request: limine.Rsdp.Request = .{};
pub var rsdp_response: limine.Rsdp.Response = undefined;

var timer_block: GenericAddress = undefined;
var timer_bits: usize = 0;
var xsdt: ?*Header = null;
var rsdt: ?*Header = null;

fn getEntries(comptime T: type, header: *Header) []align(1) const T {
    return std.mem.bytesAsSlice(T, header.getContents());
}

fn printTable(sdt: *Header) void {
    // real hw systems are packed with SSDT tables (upwards of 14)
    // beacuse of this, skip printing SSDTs so the kernel logs
    // aren't cluttered
    if (std.mem.eql(u8, "SSDT", &sdt.signature)) {
        return;
    }

    log.debug(
        "  signature={s}, base=0x{x:0>16}, length={}, revision={}",
        .{ sdt.signature, @ptrToInt(sdt), sdt.length, sdt.revision },
    );
}

pub fn getTable(signature: []const u8) ?*Header {
    if (xsdt) |x| {
        for (getEntries(u64, x)) |ent| {
            var entry = @intToPtr(*Header, ent + pmm.hhdm_response.offset);
            if (std.mem.eql(u8, signature[0..4], &entry.signature)) {
                return entry;
            }
        }
    } else {
        for (getEntries(u32, rsdt.?)) |ent| {
            var entry = @intToPtr(*Header, ent + pmm.hhdm_response.offset);
            if (std.mem.eql(u8, signature[0..4], &entry.signature)) {
                return entry;
            }
        }
    }

    return null;
}

pub fn pmSleep(us: u64) void {
    var shift: u64 = @as(u64, 1) << @truncate(u6, timer_bits);
    var target = (us * 3) + ((us * 5) / 10) + ((us * 8) / 100);

    // find out how many 'remaining' ticks to wait after 'n' overflows
    var n: u64 = target / shift;
    var remaining: u64 = target % shift;

    // bump 'remaining' to reflect current timer state
    var cur_ticks = timer_block.read(u32);
    remaining += cur_ticks;

    // adjust 'n' to reflect current timer state
    if (remaining < cur_ticks) {
        n += 1;
    } else {
        n += remaining / shift;
        remaining = remaining % shift;
    }

    // next, wait for 'n' overflows to happen
    var new_ticks: u32 = 0;
    while (n > 0) {
        new_ticks = timer_block.read(u32);
        if (new_ticks < cur_ticks) {
            n -= 1;
        }
        cur_ticks = new_ticks;
    }

    // finally, wait the 'remaining' ticks out
    while (remaining > cur_ticks) {
        new_ticks = timer_block.read(u32);
        if (new_ticks < cur_ticks) {
            break;
        }
        cur_ticks = new_ticks;
    }
}

pub fn init() void {
    if (rsdp_request.response) |rsdp|
        rsdp_response = rsdp.*;

    var xsdp = @intToPtr(*const Xsdp, rsdp_response.address);

    if (xsdp.revision >= 2 and xsdp.xsdt != 0) {
        xsdt = @intToPtr(*Header, xsdp.xsdt + pmm.hhdm_response.offset);
    } else {
        rsdt = @intToPtr(*Header, @intCast(usize, xsdp.rsdt) + pmm.hhdm_response.offset);
    }

    log.debug("ACPI tables:", .{});
    if (xsdt) |x| {
        for (getEntries(u64, x)) |ent| {
            var entry = @intToPtr(*Header, ent + pmm.hhdm_response.offset);
            printTable(entry);
        }
    } else {
        for (getEntries(u32, rsdt.?)) |ent| {
            var entry = @intToPtr(*Header, ent + pmm.hhdm_response.offset);
            printTable(entry);
        }
    }

    // setup the ACPI timer
    if (getTable("FACP")) |fadt_sdt| {
        var fadt = @ptrCast(*align(1) const Fadt, fadt_sdt.getContents());

        if (xsdp.revision >= 2 and fadt.x_pm_timer_blk.base_type == 0) {
            timer_block = fadt.x_pm_timer_blk;
            timer_block.base = timer_block.base + pmm.hhdm_response.offset;
        } else {
            if (fadt.pm_timer_blk == 0 or fadt.pm_timer_length != 4) {
                @panic("ACPI timer is unsupported/malformed");
            }

            timer_block = GenericAddress{
                .base = fadt.pm_timer_blk,
                .base_type = 1,
                .bit_width = 32,
                .bit_offset = 0,
                .access_size = 0,
            };
        }

        if ((fadt.flags & (1 << 8)) == 0) {
            timer_bits = 32;
        } else {
            timer_bits = 24;
        }

        if (timer_block.base_type == 0) {
            log.debug("Detected MMIO ACPI timer with a {}-bit counter width", .{timer_bits});
        } else {
            log.debug("Detected PIO ACPI timer with a {}-bit counter width", .{timer_bits});
        }
    } else {
        //return error.InvalidHardware;
        @panic("ACPI timer is unsupported/malformed");
    }
}
