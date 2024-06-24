const std = @import("std");
const limine = @import("limine");
const io = @import("io.zig");
const mmio = @import("../../mmio.zig");
const pmm = @import("../../mm/pmm.zig");
const apic = @import("apic.zig");
const log = std.log.scoped(.acpi);

pub const GenericAddress = extern struct {
    base_type: u8,
    bit_width: u8,
    bit_offset: u8,
    access_size: u8,
    base: u64,

    inline fn read(self: GenericAddress, comptime T: type) T {
        return if (self.base_type == 0)
            mmio.read(T, self.base)
        else
            io.read(T, @as(u16, @truncate(self.base)));
    }
};

pub const Header = extern struct {
    signature: [4]u8,
    length: u32,
    revision: u8,
    checksum: u8,
    oem: [6]u8,
    oem_table: [8]u8,
    oem_revision: u32,
    creator_id: u32,
    creator_revision: u32,

    inline fn getContents(self: *Header) []const u8 {
        return @as([*]const u8, @ptrCast(self))[0..self.length][@sizeOf(Header)..];
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

pub const Fadt = extern struct {
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

pub const Madt = extern struct {
    header: Madt.Header,
    lapic_addr: u32,
    flags: u32,
    entries: [*]u8,

    pub fn get_iso(self: *align(1) Madt, irq: u8) ?*align(1) Iso {
        var entry: *Madt.Header = undefined;
        var i: usize = 0;
        while (i < self.header.length - @sizeOf(Madt)) {
            entry = @ptrFromInt(@intFromPtr(&self.entries) + i);
            if (entry.type == 2) {
                const iso: *align(1) Iso = @ptrCast(entry);
                if (iso.irq_src == irq) return iso;
            }
            i += @max(@sizeOf(Madt.Header), entry.length);
        }
        return null;
    }

    pub fn get_ioapic(self: *align(1) Madt) !*align(1) IoApic {
        var entry: *Madt.Header = undefined;
        var i: usize = 0;
        while (i < self.header.length - @sizeOf(Madt)) {
            entry = @ptrFromInt(@intFromPtr(&self.entries) + i);
            if (entry.type == 1) return @ptrCast(entry);
            i += @max(@sizeOf(Madt.Header), entry.length);
        }
        return error.NotFound;
    }

    pub const Header = packed struct {
        type: u8,
        length: u8,
    };

    pub const Iso = packed struct {
        header: Madt.Header,
        bus_src: u8,
        irq_src: u8,
        gsi: u32,
        flags: u16,
    };

    pub const IoApic = extern struct {
        header: Madt.Header,
        ioapic: apic.ioapic.IoApic,
    };

    pub const LocalApic = packed struct {
        processor_id: u8,
        apic_id: u8,
        flags: u32,
    };
};

pub export var rsdp_request: limine.Rsdp.Request = .{};
pub var rsdp_response: limine.Rsdp.Response = undefined;

var timer_block: GenericAddress = undefined;
var timer_bits: usize = 0;
var xsdt: ?*Header = null;
var rsdt: ?*Header = null;
pub var madt: ?*align(1) Madt = null;

inline fn getEntries(comptime T: type, header: *Header) []align(1) const T {
    return std.mem.bytesAsSlice(T, header.getContents());
}

inline fn printTable(sdt: *Header) void {
    if (std.mem.eql(u8, "SSDT", &sdt.signature)) return;
    log.debug(
        "  signature={s}, base=0x{x:0>16}, length={}, revision={}",
        .{ sdt.signature, @intFromPtr(sdt), sdt.length, sdt.revision },
    );
}

pub fn getTable(signature: []const u8) ?*Header {
    if (xsdt) |x| {
        for (getEntries(u64, x)) |ent| {
            var entry = @as(*Header, @ptrFromInt(ent + pmm.hhdm_response.offset));
            if (std.mem.eql(u8, signature[0..4], &entry.signature))
                return entry;
        }
    } else {
        for (getEntries(u32, rsdt.?)) |ent| {
            var entry = @as(*Header, @ptrFromInt(ent + pmm.hhdm_response.offset));
            if (std.mem.eql(u8, signature[0..4], &entry.signature))
                return entry;
        }
    }

    return null;
}

pub fn pmSleep(us: u64) void {
    const shift: u64 = @as(u64, 1) << @as(u6, @truncate(timer_bits));
    const target = (us * 3) + ((us * 5) / 10) + ((us * 8) / 100);

    var n: u64 = target / shift;
    var remaining: u64 = target % shift;

    var cur_ticks = timer_block.read(u32);
    remaining += cur_ticks;

    if (remaining < cur_ticks) n += 1 else {
        n += remaining / shift;
        remaining = remaining % shift;
    }

    var new_ticks: u32 = 0;
    while (n > 0) {
        new_ticks = timer_block.read(u32);
        if (new_ticks < cur_ticks) n -= 1;
        cur_ticks = new_ticks;
    }

    while (remaining > cur_ticks) {
        new_ticks = timer_block.read(u32);
        if (new_ticks < cur_ticks) break;
        cur_ticks = new_ticks;
    }
}

pub fn init() void {
    if (rsdp_request.response) |rsdp|
        rsdp_response = rsdp.*;

    const xsdp = @as(*align(1) const Xsdp, @ptrFromInt(rsdp_response.address));

    if (xsdp.revision >= 2 and xsdp.xsdt != 0)
        xsdt = @as(*Header, @ptrFromInt(xsdp.xsdt + pmm.hhdm_response.offset))
    else
        rsdt = @as(*Header, @ptrFromInt(xsdp.rsdt + pmm.hhdm_response.offset));

    log.debug("ACPI tables:", .{});
    if (xsdt) |x| {
        for (getEntries(u64, x)) |ent| {
            const entry = @as(*Header, @ptrFromInt(ent + pmm.hhdm_response.offset));
            printTable(entry);
        }
    } else {
        for (getEntries(u32, rsdt.?)) |ent| {
            const entry = @as(*Header, @ptrFromInt(ent + pmm.hhdm_response.offset));
            printTable(entry);
        }
    }

    if (getTable("APIC")) |madt_sdt|
        madt = @as(*align(1) Madt, @constCast(@ptrCast(madt_sdt.getContents())));

    if (getTable("FACP")) |fadt_sdt| {
        const fadt = @as(*align(1) const Fadt, @ptrCast(fadt_sdt.getContents()));

        if (xsdp.revision >= 2 and fadt.x_pm_timer_blk.base_type == 0) {
            timer_block = fadt.x_pm_timer_blk;
            timer_block.base = timer_block.base + pmm.hhdm_response.offset;
        } else {
            if (fadt.pm_timer_blk == 0 or fadt.pm_timer_length != 4)
                @panic("ACPI timer is unsupported/malformed");

            timer_block = GenericAddress{
                .base = fadt.pm_timer_blk,
                .base_type = 1,
                .bit_width = 32,
                .bit_offset = 0,
                .access_size = 0,
            };
        }

        timer_bits = if ((fadt.flags & (1 << 8)) == 0) 32 else 24;

        if (timer_block.base_type == 0)
            log.debug("Detected MMIO ACPI timer with a {}-bit counter width", .{timer_bits})
        else
            log.debug("Detected PMIO ACPI timer with a {}-bit counter width", .{timer_bits});
    } else {
        //return error.InvalidHardware;
        @panic("ACPI timer is unsupported/malformed");
    }
}
