const std = @import("std");
const builtin = @import("builtin");
const limine = @import("limine");
const arch = @import("../aarch64.zig");

pub export var kernel_file_request: limine.KernelFile.Request = .{};

var debug_allocator_bytes: [16 * 1024 * 1024]u8 = undefined;
var debug_allocator = std.heap.FixedBufferAllocator.init(debug_allocator_bytes[0..]);
var debug_info: ?std.dwarf.DwarfInfo = null;

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    std.log.err("Kernel panic: {s}", .{message});
    dumpStackTrace(return_address orelse @returnAddress(), @frameAddress());
    std.log.err("System halted.", .{});
    arch.halt();

    unreachable;
}

fn dumpStackTrace(return_address: usize, frame_address: usize) void {
    var stack_iterator = std.debug.StackIterator.init(return_address, frame_address);

    if (builtin.mode == .Debug) init() catch |err|
        std.log.err("Failed to initialize debug info: {!}", .{err});

    std.log.err("Stack trace:", .{});
    while (stack_iterator.next()) |address|
        if (address != 0)
            if (builtin.mode == .Debug)
                printSymbol(address)
            else
                std.log.err("  0x{x:0>16}", .{address});
}

fn init() !void {
    if (debug_info != null) return;
    errdefer debug_info = null;

    if (kernel_file_request.response) |response| {
        const ptr = @as([*]const u8, @ptrFromInt(response.kernel_file.base));

        debug_info = .{
            .endian = .Little,
            .debug_frame = try getSectionSlice(ptr, ".debug_frame"),
            .debug_info = try getSectionSlice(ptr, ".debug_info"),
            .debug_abbrev = try getSectionSlice(ptr, ".debug_abbrev"),
            .debug_str = try getSectionSlice(ptr, ".debug_str"),
            .debug_line = try getSectionSlice(ptr, ".debug_line"),
            .debug_ranges = try getSectionSlice(ptr, ".debug_ranges"),
            .debug_addr = null,
            .debug_names = null,
            .debug_line_str = null,
            .debug_str_offsets = null,
            .debug_loclists = null,
            .debug_rnglists = null,
        };

        try std.dwarf.openDwarfDebugInfo(&debug_info.?, debug_allocator.allocator());
    } else {
        return error.NoKernelFile;
    }
}

fn printSymbol(address: u64) void {
    var symbol_name: []const u8 = "<no symbol info>";

    if (debug_info) |*info| brk: {
        if (info.getSymbolName(address)) |name| symbol_name = name;

        const compile_unit = info.findCompileUnit(address) catch break :brk;
        const line_info = info.getLineNumberInfo(debug_allocator.allocator(), compile_unit.*, address) catch break :brk;

        return printInfo(address, symbol_name, line_info.file_name, line_info.line);
    }

    printInfo(address, symbol_name, "???", 0);
}

fn printInfo(address: u64, symbol_name: []const u8, file_name: []const u8, line: usize) void {
    std.log.err("  0x{x:0>16}: {s} at {s}:{d}", .{ address, symbol_name, file_name, line });
}

fn getSectionData(elf: [*]const u8, shdr: []const u8) []const u8 {
    const offset = std.mem.readIntLittle(u64, shdr[24..][0..8]);
    const size = std.mem.readIntLittle(u64, shdr[32..][0..8]);

    return elf[offset .. offset + size];
}

fn getSectionName(names: []const u8, shdr: []const u8) ?[]const u8 {
    const offset = std.mem.readIntLittle(u32, shdr[0..][0..4]);
    const len = std.mem.indexOf(u8, names[offset..], "\x00") orelse return null;

    return names[offset .. offset + len];
}

fn getShdr(elf: [*]const u8, idx: usize) []const u8 {
    const sh_offset = std.mem.readIntLittle(u64, elf[40 .. 40 + 8]);
    const sh_entsize = std.mem.readIntLittle(u16, elf[58 .. 58 + 2]);
    const off = sh_offset + sh_entsize * idx;

    return elf[off .. off + sh_entsize];
}

fn getSectionSlice(elf: [*]const u8, section_name: []const u8) ![]const u8 {
    const sh_strndx = std.mem.readIntLittle(u16, elf[62 .. 62 + 2]);
    const sh_num = std.mem.readIntLittle(u16, elf[60 .. 60 + 2]);

    if (sh_strndx > sh_num) return error.ShstrndxOutOfRange;

    const section_names = getSectionData(elf, getShdr(elf, sh_strndx));

    var i: usize = 0;
    while (i < sh_num) : (i += 1) {
        const header = getShdr(elf, i);

        if (std.mem.eql(u8, getSectionName(section_names, header) orelse continue, section_name))
            return getSectionData(elf, header);
    }

    return error.SectionNotFound;
}
