const std = @import("std");
const arch = @import("../x86_64.zig");
const sched = @import("sched.zig");
const log = std.log.scoped(.interrupt);

pub const Frame = extern struct {
    const Self = @This();

    rax: u64,
    rbx: u64,
    rcx: u64,
    rdx: u64,
    rsi: u64,
    rdi: u64,
    rbp: u64,
    r8: u64,
    r9: u64,
    r10: u64,
    r11: u64,
    r12: u64,
    r13: u64,
    r14: u64,
    r15: u64,
    vec: u64,
    error_code: u64,
    rip: u64,
    cs: u64,
    rflags: u64,
    rsp: u64,
    ss: u64,

    pub fn dump(self: *Self, log_func: anytype) void {
        log_func("RAX: {X:0>16} RBX: {X:0>16} RCX: {X:0>16}", .{ self.rax, self.rbx, self.rcx });
        log_func("RDX: {X:0>16} RDI: {X:0>16} RSI: {X:0>16}", .{ self.rdx, self.rdi, self.rsi });
        log_func("RBP: {X:0>16} R8:  {X:0>16} R9:  {X:0>16}", .{ self.rbp, self.r8, self.r9 });
        log_func("R10: {X:0>16} R11: {X:0>16} R12: {X:0>16}", .{ self.r10, self.r11, self.r12 });
        log_func("R13: {X:0>16} R14: {X:0>16} R15: {X:0>16}", .{ self.r13, self.r14, self.r15 });
        log_func("RSP: {X:0>16} RIP: {X:0>16} CS:  {X:0>16}", .{ self.rsp, self.rip, self.cs });

        const cr2 = asm volatile ("mov %%cr2, %[out]"
            : [out] "=r" (-> u64),
            :
            : "memory"
        );
        log_func("Linear address: 0x{X:0>16}, EC bits: 0x{X:0>8}", .{ cr2, self.error_code });
    }
};

const Entry = packed struct {
    base_low: u16,
    selector: u16,
    ist: u8,
    flags: u8,
    base_mid: u16,
    base_high: u32,
    _reserved: u32 = 0,

    fn init(stub: Stub, ist: u8) Entry {
        const addr: u64 = @intFromPtr(stub);

        return Entry{
            .base_low = @as(u16, @truncate(addr)),
            .selector = 0x28,
            .ist = ist,
            .flags = 0x8e,
            .base_mid = @as(u16, @truncate(addr >> 16)),
            .base_high = @as(u32, @truncate(addr >> 32)),
        };
    }
};

const Stub = *const fn () callconv(.Naked) void;
const Handler = *const fn (*Frame) callconv(.C) void;
var entries: [256]Entry = undefined;
var entries_generated: bool = false;

export var handlers: [256]Handler = [_]Handler{handleException} ** 32 ++ [_]Handler{handleIrq} ** 224;

pub fn setHandler(func: anytype, vec: u8) void {
    handlers[vec] = func;
}

pub fn init() void {
    const idtr = arch.Descriptor{
        .size = @as(u16, (@sizeOf(Entry) * 256) - 1),
        .ptr = @intFromPtr(&entries),
    };

    if (!entries_generated) {
        for (genStubTable(), 0..) |stub, idx| {
            if (idx == sched.TIMER_VECTOR) {
                entries[idx] = Entry.init(stub, 1);
            } else {
                entries[idx] = Entry.init(stub, 0);
            }
        }

        entries_generated = true;
    }

    asm volatile ("lidt %[idtr]"
        :
        : [idtr] "*p" (&idtr),
    );
}

fn handleIrq(frame: *Frame) callconv(.C) void {
    log.err("CPU triggered IRQ #{}, which has no handler!", .{frame.vec});
    @panic("Unhandled IRQ");
}

fn handleException(frame: *Frame) callconv(.C) void {
    log.err("CPU exception #{}: {s}", .{ frame.vec, getExceptionName(frame.vec) });
    frame.dump(log.err);
    log.err("System halted.", .{});
    arch.halt();
}

fn getExceptionName(vec: u64) []const u8 {
    return switch (vec) {
        0 => "Division-by-zero",
        1 => "Debug",
        2 => "Non-maskable interrupt",
        3 => "Breakpoint",
        4 => "Overflow",
        5 => "Bound range exceeded",
        6 => "Invalid opcode",
        7 => "Device not available",
        8 => "Double fault",
        9 => "Coprocessor segment overrun",
        10 => "Invalid TSS",
        11 => "Segment not present",
        12 => "Stack fault",
        13 => "General protection fault",
        14 => "Page fault",
        16 => "x87 floating-point exception",
        17 => "Alignment check",
        18 => "Machine check",
        19 => "SIMD exception",
        20 => "Virtualization exception",
        30 => "Security exception",
        else => "Unknown",
    };
}

fn genStubTable() [256]Stub {
    var result = [1]Stub{undefined} ** 256;

    comptime var i: usize = 0;
    inline while (i < 256) : (i += 1) {
        result[i] = comptime makeStub(i);
    }

    return result;
}

fn makeStub(comptime vec: u8) Stub {
    return struct {
        fn stub() callconv(.Naked) void {
            const has_ec = switch (vec) {
                0x08 => true,
                0x0a...0x0e => true,
                0x11 => true,
                0x15 => true,
                0x1d...0x1e => true,
                else => false,
            };

            if (!comptime (has_ec)) {
                asm volatile ("push $0");
            }

            asm volatile ("push %[vec]"
                :
                : [vec] "i" (vec),
            );

            // zig fmt: off
            asm volatile (
                // perform a swapgs (if we came from usermode)
                \\cmpq $0x3b, 16(%rsp)
                \\jne 1f
                \\swapgs

                // push the trapframe
                \\1:
                \\push %r15
                \\push %r14
                \\push %r13
                \\push %r12
                \\push %r11
                \\push %r10
                \\push %r9
                \\push %r8
                \\push %rbp
                \\push %rdi
                \\push %rsi
                \\push %rdx
                \\push %rcx
                \\push %rbx
                \\push %rax
                \\cld

                // setup C enviroment and index into the handler
                \\lea handlers(%rip), %rbx
                \\add %[vec_off], %rbx
                \\mov %rsp, %rdi
                \\xor %rbp, %rbp
                \\call *(%rbx)

                // pop the trapframe back into place
                \\pop %rax
                \\pop %rbx
                \\pop %rcx
                \\pop %rdx
                \\pop %rsi
                \\pop %rdi
                \\pop %rbp
                \\pop %r8
                \\pop %r9
                \\pop %r10
                \\pop %r11
                \\pop %r12
                \\pop %r13
                \\pop %r14
                \\pop %r15
                \\add $16, %rsp

                // swap back to user gs (if needed)
                \\cmpq $0x3b, 8(%rsp)
                \\jne 1f
                \\swapgs

                // and away we go :-)
                \\1:
                \\iretq
                :
                : [vec_off] "i" (@as(u64, vec) * 8),
            );
        }
    }.stub;
    // zig fmt: on
}
