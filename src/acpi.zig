const std = @import("std");
const builtin = @import("builtin");
pub const uacpi = @cImport({
    @cInclude("uacpi/kernel_api.h");
    @cInclude("uacpi/acpi.h");
    @cInclude("uacpi/uacpi.h");
});
const printf = @cImport(@cInclude("printf.h"));
const mmio = @import("mmio.zig");
const pmm = @import("mm/pmm.zig");
const slab = @import("mm/slab.zig");
const arch = @import("arch.zig");
const log = std.log.scoped(.uacpi);

comptime {
    _ = @import("uacpi/uacpi_libc.zig");
}

pub export fn uacpi_kernel_raw_memory_read(address: uacpi.uacpi_phys_addr, byte_width: u8, ret: *u64) callconv(.C) uacpi.uacpi_status {
    ret.* = @intCast(switch (byte_width) {
        1 => mmio.read(u8, address + pmm.hhdm_response.offset),
        2 => mmio.read(u16, address + pmm.hhdm_response.offset),
        4 => mmio.read(u32, address + pmm.hhdm_response.offset),
        8 => mmio.read(u64, address + pmm.hhdm_response.offset),
        else => @panic("Invalid byte width"),
    });
    return uacpi.UACPI_STATUS_OK;
}

pub export fn uacpi_kernel_raw_memory_write(address: uacpi.uacpi_phys_addr, byte_width: u8, value: u64) callconv(.C) uacpi.uacpi_status {
    switch (byte_width) {
        1 => mmio.write(u8, address + pmm.hhdm_response.offset, @intCast(value)),
        2 => mmio.write(u16, address + pmm.hhdm_response.offset, @intCast(value)),
        4 => mmio.write(u32, address + pmm.hhdm_response.offset, @intCast(value)),
        8 => mmio.write(u64, address + pmm.hhdm_response.offset, @intCast(value)),
        else => @panic("Invalid byte width"),
    }
    return uacpi.UACPI_STATUS_OK;
}

pub export fn uacpi_kernel_raw_io_read(port: uacpi.uacpi_io_addr, byte_width: u8, ret: *u64) callconv(.C) uacpi.uacpi_status {
    if (builtin.cpu.arch == .x86_64) {
        ret.* = @intCast(switch (byte_width) {
            1 => arch.io.read(u8, @intCast(port)),
            2 => arch.io.read(u16, @intCast(port)),
            4 => arch.io.read(u32, @intCast(port)),
            else => @panic("Invalid byte width"),
        });
        return uacpi.UACPI_STATUS_OK;
    } else {
        return uacpi.UACPI_STATUS_NO_HANDLER;
    }
}

pub export fn uacpi_kernel_raw_io_write(port: uacpi.uacpi_io_addr, byte_width: u8, value: u64) callconv(.C) uacpi.uacpi_status {
    if (builtin.cpu.arch == .x86_64) {
        switch (byte_width) {
            1 => arch.io.write(u8, @intCast(port), @intCast(value)),
            2 => arch.io.write(u16, @intCast(port), @intCast(value)),
            4 => arch.io.write(u32, @intCast(port), @intCast(value)),
            else => @panic("Invalid byte width"),
        }
        return uacpi.UACPI_STATUS_OK;
    } else {
        return uacpi.UACPI_STATUS_NO_HANDLER;
    }
}

pub const IoMap = extern struct {
    port: u16,
    length: usize,
};

pub export fn uacpi_kernel_io_map(port: uacpi.uacpi_io_addr, length: usize, ret: **IoMap) callconv(.C) uacpi.uacpi_status {
    if (builtin.cpu.arch == .x86_64) {
        ret.* = slab.allocator.create(IoMap) catch undefined;
        ret.*.port = @intCast(port);
        ret.*.length = length;
        return uacpi.UACPI_STATUS_OK;
    } else {
        return uacpi.UACPI_STATUS_NO_HANDLER;
    }
}

pub export fn uacpi_kernel_io_unmap(ret: *IoMap) callconv(.C) uacpi.uacpi_status {
    if (builtin.cpu.arch == .x86_64) {
        slab.allocator.destroy(ret);
        return uacpi.UACPI_STATUS_OK;
    } else {
        return uacpi.UACPI_STATUS_NO_HANDLER;
    }
}

pub export fn uacpi_kernel_io_read(handle: *IoMap, offset: usize, byte_width: u8, ret: *u64) callconv(.C) uacpi.uacpi_status {
    if (builtin.cpu.arch == .x86_64) {
        if (offset >= handle.length) return uacpi.UACPI_STATUS_INVALID_ARGUMENT;
        return uacpi_kernel_raw_io_read(handle.port + offset, byte_width, ret);
    } else {
        return uacpi.UACPI_STATUS_NO_HANDLER;
    }
}

pub export fn uacpi_kernel_io_write(handle: *IoMap, offset: usize, byte_width: u8, value: u64) callconv(.C) uacpi.uacpi_status {
    if (builtin.cpu.arch == .x86_64) {
        if (offset >= handle.length) return uacpi.UACPI_STATUS_INVALID_ARGUMENT;
        return uacpi_kernel_raw_io_write(handle.port + offset, byte_width, value);
    } else {
        return uacpi.UACPI_STATUS_NO_HANDLER;
    }
}

pub export fn uacpi_kernel_pci_read(address: *uacpi.uacpi_pci_address, offset: usize, byte_width: u8, ret: *u64) callconv(.C) uacpi.uacpi_status {
    _ = address;
    _ = offset;
    _ = byte_width;
    _ = ret;
    return uacpi.UACPI_STATUS_UNIMPLEMENTED;
}

pub export fn uacpi_kernel_pci_write(address: *uacpi.uacpi_pci_address, offset: usize, byte_width: u8, value: u64) callconv(.C) uacpi.uacpi_status {
    _ = address;
    _ = offset;
    _ = byte_width;
    _ = value;
    return uacpi.UACPI_STATUS_UNIMPLEMENTED;
}

pub export fn uacpi_kernel_map(address: uacpi.uacpi_phys_addr, length: usize) callconv(.C) u64 {
    _ = length;
    return address + pmm.hhdm_response.offset;
}

pub export fn uacpi_kernel_unmap(address: u64) callconv(.C) void {
    _ = address;
}

pub export fn uacpi_kernel_alloc(size: usize) callconv(.C) [*]u8 {
    const ret = slab.allocator.alloc(u8, size) catch undefined;
    return ret.ptr;
}

pub export fn uacpi_kernel_calloc(count: usize, size: usize) callconv(.C) [*]u8 {
    const ret = slab.allocator.alloc(u8, count * size) catch undefined;
    return ret.ptr;
}

pub export fn uacpi_kernel_free(address: [*]u8, size: usize) callconv(.C) void {
    slab.allocator.free(address[0..size]);
}

pub export fn uacpi_kernel_log(level: uacpi.uacpi_log_level, string: [*c]const u8) callconv(.C) void {
    switch (level) {
        uacpi.UACPI_LOG_TRACE => log.debug("{s}", .{string}),
        uacpi.UACPI_LOG_INFO => log.info("{s}", .{string}),
        uacpi.UACPI_LOG_WARN => log.warn("{s}", .{string}),
        uacpi.UACPI_LOG_ERROR => log.err("{s}", .{string}),
        else => @panic("Unknown log level"),
    }
}
pub export fn uacpi_kernel_get_ticks() callconv(.C) u64 {
    return 0;
}

pub export fn uacpi_kernel_stall(usec: u8) callconv(.C) void {
    _ = usec;
}

pub export fn uacpi_kernel_sleep(msec: u64) callconv(.C) void {
    _ = msec;
}

pub export fn uacpi_kernel_create_mutex() callconv(.C) *arch.Spinlock {
    //var ret = arch.Spinlock{};
    //return &ret;
    return undefined;
}

pub export fn uacpi_kernel_free_mutex(_: *arch.Spinlock) callconv(.C) void {}

pub export fn uacpi_kernel_get_thread_id() callconv(.C) uacpi.uacpi_thread_id {
    return null;
}

pub export fn uacpi_kernel_acquire_mutex(_: *arch.Spinlock, _: u16) callconv(.C) bool {
    return true;
}

pub export fn uacpi_kernel_release_mutex(_: *arch.Spinlock) callconv(.C) void {}

pub export fn uacpi_kernel_create_event() callconv(.C) uacpi.uacpi_handle {
    return undefined;
}
pub export fn uacpi_kernel_free_event(_: uacpi.uacpi_handle) callconv(.C) void {}
pub export fn uacpi_kernel_wait_for_event(_: uacpi.uacpi_handle, _: u16) callconv(.C) bool {
    return true;
}
pub export fn uacpi_kernel_signal_event(_: uacpi.uacpi_handle) callconv(.C) void {}
pub export fn uacpi_kernel_reset_event(_: uacpi.uacpi_handle) callconv(.C) void {}

pub export fn uacpi_kernel_handle_firmware_request(_: [*c]uacpi.uacpi_firmware_request) callconv(.C) uacpi.uacpi_status {
    return uacpi.UACPI_STATUS_UNIMPLEMENTED;
}
pub export fn uacpi_kernel_install_interrupt_handler(irq: u32, _: uacpi.uacpi_interrupt_handler, ctx: uacpi.uacpi_handle, out_irq_handle: [*c]uacpi.uacpi_handle) callconv(.C) uacpi.uacpi_status {
    _ = irq;
    _ = ctx;
    _ = out_irq_handle;
    return uacpi.UACPI_STATUS_UNIMPLEMENTED;
}
pub export fn uacpi_kernel_uninstall_interrupt_handler(_: uacpi.uacpi_interrupt_handler, irq_handle: uacpi.uacpi_handle) callconv(.C) uacpi.uacpi_status {
    _ = irq_handle;
    return uacpi.UACPI_STATUS_UNIMPLEMENTED;
}
pub export fn uacpi_kernel_create_spinlock() callconv(.C) *arch.Spinlock {
    //var ret = arch.Spinlock{};
    //return &ret;
    return undefined;
}

pub export fn uacpi_kernel_free_spinlock(_: *arch.Spinlock) callconv(.C) void {}

pub export fn uacpi_kernel_spinlock_lock(_: *arch.Spinlock) callconv(.C) uacpi.uacpi_cpu_flags {
    return undefined;
}

pub export fn uacpi_kernel_spinlock_unlock(_: *arch.Spinlock, _: uacpi.uacpi_cpu_flags) callconv(.C) void {}

pub export fn uacpi_kernel_schedule_work(_: uacpi.uacpi_work_type, _: uacpi.uacpi_work_handler, _: uacpi.uacpi_handle) uacpi.uacpi_status {
    return uacpi.UACPI_STATUS_UNIMPLEMENTED;
}

pub export fn uacpi_kernel_wait_for_work_completion() uacpi.uacpi_status {
    return uacpi.UACPI_STATUS_UNIMPLEMENTED;
}
