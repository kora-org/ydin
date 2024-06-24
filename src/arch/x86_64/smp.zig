const std = @import("std");
const arch = @import("../x86_64.zig");
const limine = @import("limine");
const pmm = @import("../../mm/pmm.zig");
const vmm = @import("vmm.zig");
const slab = @import("../../mm/slab.zig");
const gdt = @import("gdt.zig");
const interrupt = @import("interrupt.zig");
const sched = @import("sched.zig");
const acpi = @import("acpi.zig");
const apic = @import("apic.zig");
const cpu = @import("cpu.zig");
const log = std.log.scoped(.smp);

pub export var smp_request: limine.Smp.Request = .{};
pub var smp_response: limine.Smp.Response = undefined;

pub const CoreInfo = struct {
    processor_id: u32,
    lapic_id: u32,
    ticks_per_ms: u64 = 0,
    user_stack: u64 = 0,
    tss: gdt.Tss = .{},
    is_bsp: bool = false,
    current_thread: ?*sched.Thread = null,
};

var booted_cores = std.atomic.Value(u16).init(1);

pub fn isBsp() bool {
    if (arch.rdmsr(0xc0000101) == 0)
        return true;

    return getCoreInfo().is_bsp;
}

pub inline fn getCoreInfo() *CoreInfo {
    return @ptrFromInt(arch.rdmsr(0xc0000101));
}

pub inline fn setCoreInfo(core_info: *CoreInfo) void {
    arch.wrmsr(0xc0000101, @intFromPtr(core_info));
}

fn createCoreInfo(cpu_info: *limine.Smp.Cpu) void {
    const core_info = slab.allocator.create(CoreInfo) catch unreachable;
    core_info.* = .{
        .processor_id = cpu_info.processor_id,
        .lapic_id = cpu_info.lapic_id,
    };
    setCoreInfo(core_info);
}

pub export fn smpEntry(cpu_info: *limine.Smp.Cpu) callconv(.C) noreturn {
    vmm.pagemap.load();
    createCoreInfo(cpu_info);
    gdt.init();
    interrupt.init();
    cpu.init();
    apic.lapic.enable();

    getCoreInfo().tss.rsp0 = sched.createKernelStack().?;
    getCoreInfo().tss.init();
    getCoreInfo().tss.flush();

    _ = booted_cores.fetchAdd(1, .monotonic);
    sched.init() catch unreachable;

    while (true) {}
}

pub fn init() !void {
    if (smp_request.response) |smp| {
        log.debug("Detected {} CPUs.", .{smp.cpu_count});

        for (smp.getCpus()) |cpu_info| {
            if (cpu_info.lapic_id == smp.bsp_lapic_id) {
                createCoreInfo(cpu_info);
                getCoreInfo().is_bsp = true;

                getCoreInfo().tss.rsp0 = sched.createKernelStack().?;
                getCoreInfo().tss.init();
                getCoreInfo().tss.flush();

                cpu.init();
                apic.lapic.enable();

                continue;
            }

            cpu_info.goto = &smpEntry;
        }

        while (booted_cores.load(.monotonic) != smp.cpu_count) {}
        log.info("All CPUs are online!", .{});
    }
}
