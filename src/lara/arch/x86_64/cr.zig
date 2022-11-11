pub fn read(comptime cr: i8) u64 {
    return switch(cr) {
        0 => asm volatile("mov %%cr0, %[ret]"
            : [ret] "=r"(-> u64),
        ),

        2 => asm volatile("mov %%cr2, %[ret]"
            : [ret] "=r"(-> u64),
        ),

        3 => asm volatile("mov %%cr3, %[ret]"
            : [ret] "=r"(-> u64),
        ),

        4 => asm volatile("mov %%cr4, %[ret]"
            : [ret] "=r"(-> u64),
        ),

        8 => asm volatile("mov %%cr8, %[ret]"
            : [ret] "=r"(-> u64),
        ),

        else => unreachable,
    };
}

pub fn write(comptime cr: i8, value: u64) void {
    switch(cr) {
        0 => asm volatile("mov %[value], %%cr0"
            : [value] "r"(value),
        ),

        2 => asm volatile("mov %[value], %%cr2"
            : [value] "r"(value),
        ),

        3 => asm volatile("mov %[value], %%cr3"
            : [value] "r"(value),
        ),

        4 => asm volatile("mov %[value], %%cr4"
            : [value] "r"(value),
        ),

        8 => asm volatile("mov %[value], %%cr8"
            : [value] "r"(value),
        ),

        else => unreachable,
    }
}
