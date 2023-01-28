const std = @import("std");
const arch = @import("../x86_64.zig");
const limine = @import("limine");
const pmm = @import("mm/pmm.zig");
const vmm = @import("mm/vmm.zig");
const slab = @import("mm/slab.zig");
const gdt = @import("gdt.zig");
const interrupt = @import("interrupt.zig");
const sched = @import("sched.zig");
const lapic = @import("lapic.zig");
const cpu = @import("cpu.zig");
const log = std.log.scoped(.smp);

pub export var smp_request: limine.Smp.Request = .{};
pub var smp_response: limine.Smp.Response = undefined;

pub const CoreInfo = struct {
    processor_id: u32,
    lapic_id: u32,
    ticks_per_ms: u64 = 0,
    user_stack: u64 = 0,
    tss: gdt.Tss = undefined,
    is_bsp: bool = false,
    current_thread: ?*sched.Thread = null,
};

var booted_cores: std.atomic.Atomic(u16) = .{ .value = 1 };

pub fn isBsp() bool {
    if (arch.rdmsr(0xc0000101) == 0)
        return true;

    return getCoreInfo().is_bsp;
}

pub inline fn getCoreInfo() *CoreInfo {
    return @intToPtr(*CoreInfo, arch.rdmsr(0xc0000101));
}

pub inline fn setCoreInfo(core_info: *CoreInfo) void {
    arch.wrmsr(0xc0000101, @ptrToInt(core_info));
}

fn createCoreInfo(cpu_info: *limine.Smp.Cpu) void {
    var core_info = slab.allocator.create(CoreInfo) catch unreachable;

    core_info.* = std.mem.zeroInit(CoreInfo, .{
        .lapic_id = cpu_info.lapic_id,
        .processor_id = cpu_info.processor_id,
    });

    setCoreInfo(core_info);
}

pub export fn smpEntry(cpu_info: *limine.Smp.Cpu) callconv(.C) noreturn {
    // setup the important stuff
    vmm.pagemap.load();
    createCoreInfo(cpu_info);
    gdt.init();
    interrupt.init();
    cpu.init(isBsp());
    lapic.enable();

    // load the TSS
    getCoreInfo().tss = std.mem.zeroes(gdt.Tss);
    getCoreInfo().tss.rsp[0] = sched.createKernelStack().?;
    getCoreInfo().tss.init();
    getCoreInfo().tss.flush();

    // let BSP know we're done, then off we go!
    _ = booted_cores.fetchAdd(1, .Monotonic);
    sched.init() catch unreachable;

    log.debug("CPU {} online!", .{cpu_info.processor_id});
    while (true) {}
}

pub fn init() void {
    if (smp_request.response) |smp| {
        log.debug("Detected {} CPUs.", .{smp.cpu_count});

        for (smp.getCpus()) |cpu_info| {
            if (cpu_info.lapic_id == smp.bsp_lapic_id) {
                createCoreInfo(cpu_info);
                getCoreInfo().is_bsp = true;

                // load the TSS
                getCoreInfo().tss = std.mem.zeroes(gdt.Tss);
                getCoreInfo().tss.rsp[0] = sched.createKernelStack().?;
                getCoreInfo().tss.init();
                getCoreInfo().tss.flush();

                lapic.init();
                continue;
            }

            cpu_info.goto = &smpEntry;
        }

        while (booted_cores.load(.Monotonic) != smp.cpu_count) {}
    }
}
