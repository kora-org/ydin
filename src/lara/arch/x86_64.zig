const std = @import("std");

pub fn enableInterrupts() void {
    asm volatile("sti");
}

pub fn disableInterrupts() void {
    asm volatile("cli");
}

pub fn pause() void {
    asm volatile("pause" ::: "memory");
}

pub fn halt() void {
    disableInterrupts();
    while(true) {
        asm volatile("hlt");
    }
}

/// x86 specific functions

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

    asm volatile("cpuid"
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

pub fn out8(port: u16) u8 {
    return asm volatile("inb %[port],%[ret]"
        : [ret] "={al}"(-> u8),
        : [port] "N{dx}"(port),
    );
}

pub fn out16(port: u16) u16 {
    return asm volatile("inw %[port],%[ret]"
        : [ret] "={al}"(-> u16),
        : [port] "N{dx}"(port),
    );
}

pub fn out32(port: u16) u32 {
    return asm volatile("inl %[port],%[ret]"
        : [ret] "={eax}"(-> u32),
        : [port] "N{dx}"(port),
    );
}

pub fn in8(port: u16, value: u8) void {
    asm volatile("outb %[value],%[port]"
        :
        : [value] "{al}"(value),
          [port] "N{dx}"(port),
    );
}

pub fn in16(port: u16, value: u16) void {
    asm volatile("outw %[value],%[port]"
        :
        : [value] "{al}"(value),
          [port] "N{dx}"(port),
    );
}

pub fn in32(port: u16, value: u32) void {
    asm volatile("outl %[value],%[port]"
        :
        : [value] "{eax}"(value),
          [port] "N{dx}"(port),
    );
}
