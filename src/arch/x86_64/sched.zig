const std = @import("std");
const interrupt = @import("interrupt.zig");
const arch = @import("../x86_64.zig");
const lapic = @import("apic/lapic.zig");
//const proc = @import("proc.zig");
const smp = @import("smp.zig");
const pmm = @import("mm/pmm.zig");
const vmm = @import("mm/vmm.zig");
const slab = @import("mm/slab.zig");

pub const Thread = struct {
    id: usize = 0,
    link: Node,
    context: interrupt.Frame,
    kernel_stack: u64,
    //proc: *proc.Process,
};

pub const Node = struct {
    next: ?*Node = undefined,
};

pub fn Queue(comptime T: type, comptime member_name: []const u8) type {
    return struct {
        head: ?*Node = null,
        tail: ?*Node = null,
        lock: arch.Spinlock = .{},

        fn refToNode(ref: *T) *Node {
            return &@field(ref, member_name);
        }

        fn nodeToRef(node: *Node) *T {
            return @fieldParentPtr(T, member_name, node);
        }

        pub fn enqueue(self: *@This(), node: *T) void {
            self.lock.acq();
            defer self.lock.rel();

            const hook = refToNode(node);
            hook.next = null;

            if (self.tail) |tail_nonnull| {
                tail_nonnull.next = hook;
                self.tail = hook;
            } else {
                std.debug.assert(self.head == null);
                self.head = hook;
                self.tail = hook;
            }
        }

        pub fn dequeue(self: *@This()) ?*T {
            self.lock.acq();
            defer self.lock.rel();

            if (self.head) |head_nonnull| {
                if (head_nonnull.next) |next| {
                    self.head = next;
                } else {
                    self.head = null;
                    self.tail = null;
                }
                return nodeToRef(head_nonnull);
            }
            return null;
        }
    };
}

pub const TIMER_VECTOR = 0x30;
var thread_list = Queue(Thread, "link"){};
var sched_lock = arch.Spinlock{};

pub fn exit() noreturn {
    smp.getCoreInfo().cur_thread = null;
    lapic.oneshot(TIMER_VECTOR, 1);

    while (true) {}
}

pub fn createKernelStack() ?u64 {
    if (pmm.alloc(1)) |page| {
        return (@intFromPtr(page) + std.mem.page_size) + pmm.hhdm_response.offset;
    } else {
        return null;
    }
}

fn getNextThread() *Thread {
    sched_lock.acq();
    defer sched_lock.rel();

    if (thread_list.dequeue()) |elem| {
        return elem;
    } else {
        // set a new timer for later
        sched_lock.rel();
        lapic.submitEoi(TIMER_VECTOR);
        lapic.oneshot(TIMER_VECTOR, 20);

        vmm.pagemap.load();
        arch.enableInterrupts();

        while (true) {}
    }
}

pub fn reschedule(frame: *interrupt.Frame) callconv(.C) void {
    if (smp.getCoreInfo().cur_thread) |old_thread| {
        old_thread.context = frame.*;
        smp.getCoreInfo().current_thread = null;

        sched_lock.acq();
        thread_list.enqueue(old_thread);
        sched_lock.rel();
    }

    var thread = getNextThread();
    smp.getCoreInfo().current_thread = thread;
    smp.getCoreInfo().tss.rsp0 = thread.kernel_stack;

    frame.* = thread.context;
    thread.proc.pagemap.load();

    lapic.submitEoi(TIMER_VECTOR);
    lapic.oneshot(TIMER_VECTOR, 20);
}

pub fn spawnKernelThread(func: *const fn (u64) noreturn, arg: ?u64) !*Thread {
    var thread = slab.allocator.create(Thread);
    errdefer slab.allocator.destroy(thread);

    thread.kernel_stack = createKernelStack() orelse return error.OutOfMemory;
    thread.context = std.mem.zeroes(interrupt.Frame);
    //thread.proc = &proc.kernel_process;

    thread.context.rip = @intFromPtr(func);
    thread.context.rsp = thread.kernel_stack;
    thread.context.ss = 0x30;
    thread.context.cs = 0x28;
    thread.context.rflags = 0x202;

    if (arg) |elem| {
        thread.context.rdi = elem;
    }

    sched_lock.acq();
    thread_list.enqueue(thread);
    sched_lock.rel();

    return thread;
}

pub fn init() !void {
    smp.getCoreInfo().tss.ist1 = createKernelStack() orelse return error.OutOfMemory;

    lapic.oneshot(TIMER_VECTOR, 20);
    arch.enableInterrupts();
}
