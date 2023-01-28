const std = @import("std");
const arch = @import("../x86_64.zig");
//const smp = @import("smp.zig");
const log = std.log.scoped(.fpu);

const SaveType = enum {
    fxsave,
    xsave,
    xsaveopt,
    xsavec,
    xsaves,
};

const State = extern struct {
    // legacy x87 fpu context
    ctrl: u16,
    status: u16,
    tag: u16,
    fop: u16,
    ip: u64,
    dp: u64,

    // mxcsr control double-words
    mxcsr: u32,
    mxcsr_mask: u32,

    // x87 floating point regs
    st_regs: [32]u32,

    // SSE simd regs and padding
    xmm_regs: [64]u32,
    padding: [24]u32,
};

const XSaveState = extern struct {
    state: State,
    xfeatures: u64,
    xcomp_bv: u64,
    reserved: [6]u64,
};

const supported_mask = 0x602e7;

var storage_size: usize = 0;
var storage_align: usize = 0;
var mode: SaveType = undefined;

inline fn wrxcr(comptime reg: usize, value: u64) void {
    var edx: u32 = @truncate(u32, value >> 32);
    var eax: u32 = @truncate(u32, value);

    asm volatile ("xsetbv"
        :
        : [eax] "{eax}" (eax),
          [edx] "{edx}" (edx),
          [ecx] "{ecx}" (reg),
        : "memory"
    );
}

pub fn restore(save_area: []const u8) void {
    std.debug.assert(@ptrToInt(&save_area) % storage_align == 0);

    var rbfm: u32 = 0xffffffff;
    var rbfm_high: u32 = 0xffffffff;

    switch (mode) {
        .xsave, .xsavec, .xsaveopt => {
            asm volatile ("xrstorq (%[context])"
                :
                : [context] "r" (save_area),
                  [eax] "{eax}" (rbfm),
                  [edx] "{edx}" (rbfm_high),
                : "memory"
            );
        },
        .xsaves => {
            asm volatile ("xrstorsq (%[context])"
                :
                : [context] "r" (save_area),
                  [eax] "{eax}" (rbfm),
                  [edx] "{edx}" (rbfm_high),
                : "memory"
            );
        },
        .fxsave => {
            asm volatile ("fxrstorq (%[context])"
                :
                : [context] "r" (save_area),
                : "memory"
            );
        },
    }
}

pub fn save(save_area: []const u8) void {
    std.debug.assert(@ptrToInt(&save_area) % storage_align == 0);

    var rbfm: u32 = 0xffffffff;
    var rbfm_high: u32 = 0xffffffff;

    switch (mode) {
        .xsave => {
            asm volatile ("xsaveq (%[context])"
                :
                : [context] "r" (@ptrToInt(&save_area)),
                  [eax] "{eax}" (rbfm),
                  [edx] "{edx}" (rbfm_high),
                : "memory"
            );
        },
        .xsavec => {
            asm volatile ("xsavecq (%[context])"
                :
                : [context] "r" (@ptrToInt(&save_area)),
                  [eax] "{eax}" (rbfm),
                  [edx] "{edx}" (rbfm_high),
                : "memory"
            );
        },
        .xsaves => {
            asm volatile ("xsavesq (%[context])"
                :
                : [context] "r" (@ptrToInt(&save_area)),
                  [eax] "{eax}" (rbfm),
                  [edx] "{edx}" (rbfm_high),
                : "memory"
            );
        },
        .xsaveopt => {
            asm volatile ("xsaveoptq (%[context])"
                :
                : [context] "r" (@ptrToInt(&save_area)),
                  [eax] "{eax}" (rbfm),
                  [edx] "{edx}" (rbfm_high),
                : "memory"
            );
        },
        .fxsave => {
            asm volatile ("fxsaveq (%[context])"
                :
                : [context] "r" (@ptrToInt(&save_area)),
                : "memory"
            );
        },
    }
}

pub fn init(bsp: bool) void {
    // enable SSE & FXSAVE/FXRSTOR
    arch.cr.write(4, arch.cr.read(4) | (3 << 9));

    if (arch.cpuid(1, 0).ecx & (1 << 26) != 0) {
        arch.cr.write(4, arch.cr.read(4) | (1 << 18));
        storage_align = 64;
        mode = .xsave;

        var result = arch.cpuid(0x0d, 1);
        if (result.eax & (1 << 0) != 0) {
            mode = .xsaveopt;
        }
        if (result.eax & (1 << 1) != 0) {
            mode = .xsavec;
        }
        if (result.eax & (1 << 3) != 0) {
            mode = .xsaves;

            // clear XSS, since munix doesn't support any supervisor states
            arch.wrmsr(0xda0, 0);
        }

        wrxcr(0, @as(u64, arch.cpuid(0x0d, 0).eax) & supported_mask);
        result = arch.cpuid(0x0d, 0);

        if (bsp) {
            log.info("supported extensions bitmask: 0x{X}", .{result.eax});
        }

        switch (mode) {
            .xsave, .xsaveopt => {
                storage_size = result.ecx;
            },
            .xsavec => {
                storage_size = result.ebx;
            },
            .xsaves => {
                storage_size = arch.cpuid(0x0d, 1).ebx;
            },
            else => {},
        }
    } else {
        storage_size = 512;
        storage_align = 16;
        mode = .fxsave;
    }

    if (bsp) {
        log.info(
            "using \"{s}\" instruction (with size={}) for FPU context management",
            .{ @tagName(mode), storage_size },
        );
    }
}
