const std = @import("std");

pub fn enableInterrupts() void {
    asm volatile ("sti");
}

pub fn disableInterrupts() void {
    asm volatile ("cli");
}

pub fn pause() void {
    asm volatile ("pause" ::: "memory");
}

pub fn halt() void {
    disableInterrupts();
    while (true) {
        asm volatile ("hlt");
    }
}

pub const pmm = @import("x86_64/pmm.zig");

/// x86 specific functions
pub const io = @import("x86_64/io.zig");
pub const cr = @import("x86_64/cr.zig");

pub const CpuidResult = struct {
    eax: u32,
    ebx: u32,
    ecx: u32,
    edx: u32,
};

pub fn cpuid(leaf: u32) CpuidResult {
    return cpuidWithSubleaf(leaf, 0);
}

pub fn cpuidWithSubleaf(leaf: u32, sub_leaf: u32) CpuidResult {
    var eax: u32 = undefined;
    var ebx: u32 = undefined;
    var ecx: u32 = undefined;
    var edx: u32 = undefined;

    asm volatile ("cpuid"
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx),
        : [eax] "{eax}" (leaf),
          [ecx] "{ecx}" (sub_leaf),
    );

    return CpuidResult{
        .eax = eax,
        .ebx = ebx,
        .ecx = ecx,
        .edx = edx,
    };
}

pub fn cpuidMax(leaf: u32) [2]u32 {
    const result = cpuid(leaf);
    return [2]u32{
        result.eax,
        result.ebx,
    };
}
