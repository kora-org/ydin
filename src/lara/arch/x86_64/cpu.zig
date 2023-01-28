const std = @import("std");
const arch = @import("../x86_64.zig");
const cr = @import("cr.zig");
const fpu = @import("fpu.zig");
const smp = @import("smp.zig");
const interrupt = @import("interrupt.zig");
const log = std.log.scoped(.cpu);

pub export fn handleSyscall(frame: *interrupt.Frame) callconv(.C) void {
    log.err("unsupported syscall #{}!", .{frame.rax});
    while (true) {}
}

pub fn init() void {
    fpu.init();

    // set the CPU to a acceptable state
    cr.write(0, (cr.read(0) & ~@as(u64, 1 << 2)) | 0b10);
    cr.write(4, cr.read(4) | (1 << 7));

    // enable pkeys (if supported)
    if (arch.cpuid(7, 0).ecx & (1 << 3) != 0) {
        cr.write(4, cr.read(4) | (1 << 22));
    }

    // enable umip (if supported)
    if (arch.cpuid(7, 0).ecx & (1 << 2) != 0) {
        cr.write(4, cr.read(4) | (1 << 11));
    }

    // enable syscall
    arch.wrmsr(0xC0000081, (@as(u64, 0x30 | 0b11) << 48) | ((@as(u64, 0x28) << 32)));
    arch.wrmsr(0xC0000082, @ptrToInt(&syscallEntry));
    arch.wrmsr(0xC0000080, arch.rdmsr(0xC0000080) | 1);
    arch.wrmsr(0xC0000084, ~@as(u32, 2));
}

fn syscallEntry() callconv(.Naked) void {
    // zig fmt: off
    asm volatile (
        // perform a swapgs and switch to the kernel stack 
        \\swapgs
        \\movq %rsp, %%gs:16
        \\movq %%gs:28, %rsp
        \\sti

        // create a fake trapframe header
        \\pushq $0x38
        \\pushq %%gs:16
        \\pushq %r11
        \\pushq $0x40
        \\pushq %rcx
        \\pushq $0
        \\pushq $0

        // push remaining registers
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

        // call the syscall handler
        \\mov %rsp, %rdi
        \\xor %rbp, %rbp
        \\call handleSyscall

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

        // restore the context back to place
        \\cli
        \\mov %rsp, %%gs:16
        \\swapgs
        \\sysretq
    );
    // zig fmt: on
}
