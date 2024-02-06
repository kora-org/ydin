const std = @import("std");
const builtin = @import("builtin");
const limine = @import("limine");
const arch = @import("../../arch.zig");

pub export var kernel_file_request: limine.KernelFile.Request = .{};

var debug_allocator_bytes: [16 * 1024 * 1024]u8 = undefined;
var debug_allocator = std.heap.FixedBufferAllocator.init(debug_allocator_bytes[0..]);
var debug_info: ?std.dwarf.DwarfInfo = null;

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, return_address: ?usize) noreturn {
    _ = return_address; // autofix
    std.log.err("Kernel panic: {s}", .{message});

    // FIXME: currently page faults when loading debug infp
    //var stack_iterator = std.debug.StackIterator.init(return_address orelse @returnAddress(), @frameAddress());
    //if (builtin.mode == .Debug) init() catch |err|
    //    std.log.err("Failed to initialize debug info: {!}", .{err});
    //
    //std.log.err("Stack trace:", .{});
    //while (stack_iterator.next()) |address|
    //    if (address != 0)
    //        if (builtin.mode == .Debug)
    //            printSymbol(address)
    //        else
    //            std.log.err("  0x{x:0>16}", .{address});

    std.log.err("System halted.", .{});
    arch.halt();

    unreachable;
}

fn init() !void {
    if (debug_info != null) return;
    errdefer debug_info = null;

    if (kernel_file_request.response) |response| {
        const ptr = @as([*]const u8, @ptrFromInt(response.kernel_file.base));

        debug_info = .{
            .endian = .little,
            .is_macho = false,
        };
        setSection(&debug_info.?, .debug_frame, try getSectionSlice(ptr, ".debug_frame"), try getSectionAddress(ptr, ".debug_frame"));
        setSection(&debug_info.?, .debug_info, try getSectionSlice(ptr, ".debug_info"), try getSectionAddress(ptr, ".debug_info"));
        setSection(&debug_info.?, .debug_abbrev, try getSectionSlice(ptr, ".debug_abbrev"), try getSectionAddress(ptr, ".debug_abbrev"));
        setSection(&debug_info.?, .debug_str, try getSectionSlice(ptr, ".debug_str"), try getSectionAddress(ptr, ".debug_str"));
        setSection(&debug_info.?, .debug_line, try getSectionSlice(ptr, ".debug_line"), try getSectionAddress(ptr, ".debug_line"));
        setSection(&debug_info.?, .debug_ranges, try getSectionSlice(ptr, ".debug_ranges"), try getSectionAddress(ptr, ".debug_ranges"));
        setSection(&debug_info.?, .debug_addr, null, null);
        setSection(&debug_info.?, .debug_names, null, null);
        setSection(&debug_info.?, .debug_line_str, null, null);
        setSection(&debug_info.?, .debug_str_offsets, null, null);
        setSection(&debug_info.?, .debug_loclists, null, null);
        setSection(&debug_info.?, .debug_rnglists, null, null);

        try std.dwarf.openDwarfDebugInfo(&debug_info.?, debug_allocator.allocator());
    } else {
        return error.NoKernelFile;
    }
}

inline fn setSection(dwarf_info: *std.dwarf.DwarfInfo, section: std.dwarf.DwarfSection, section_data: ?[]const u8, section_address: ?u64) void {
    if (section_data) |data| {
        if (section_address) |address| {
            dwarf_info.sections[@intFromEnum(section)] = .{
                .data = data,
                .virtual_address = address,
                .owned = false,
            };
        }
    } else {
        dwarf_info.sections[@intFromEnum(section)] = null;
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
    const offset = std.mem.readInt(u64, shdr[24..][0..8], .little);
    const size = std.mem.readInt(u64, shdr[32..][0..8], .little);

    return elf[offset .. offset + size];
}

fn getSectionName(names: []const u8, shdr: []const u8) ?[]const u8 {
    const offset = std.mem.readInt(u32, shdr[0..][0..4], .little);
    const len = std.mem.indexOf(u8, names[offset..], "\x00") orelse return null;

    return names[offset .. offset + len];
}

fn getShdr(elf: [*]const u8, idx: usize) []const u8 {
    const sh_offset = std.mem.readInt(u64, elf[40 .. 40 + 8], .little);
    const sh_entsize = std.mem.readInt(u16, elf[58 .. 58 + 2], .little);
    const off = sh_offset + sh_entsize * idx;

    return elf[off .. off + sh_entsize];
}

fn getSectionAddress(elf: [*]const u8, section_name: []const u8) !u64 {
    const sh_strndx = std.mem.readInt(u16, elf[62 .. 62 + 2], .little);
    const sh_num = std.mem.readInt(u16, elf[60 .. 60 + 2], .little);

    if (sh_strndx > sh_num) return error.ShstrndxOutOfRange;

    const section_names = getSectionData(elf, getShdr(elf, sh_strndx));

    var i: usize = 0;
    while (i < sh_num) : (i += 1) {
        const header = getShdr(elf, i);

        if (std.mem.eql(u8, getSectionName(section_names, header) orelse continue, section_name))
            return std.mem.readInt(u64, header[24..][0..8], .little);
    }

    return error.SectionNotFound;
}

fn getSectionSlice(elf: [*]const u8, section_name: []const u8) ![]const u8 {
    const sh_strndx = std.mem.readInt(u16, elf[62 .. 62 + 2], .little);
    const sh_num = std.mem.readInt(u16, elf[60 .. 60 + 2], .little);

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
