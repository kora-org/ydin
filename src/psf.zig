const std = @import("std");

// TODO: Add support for Unicode on PSF1
pub const Psf1 = struct {
    pub const Header = struct {
        magic: u16 = 0x0436,
        flags: u8,
        height: u8,
    };

    data: []const u8,
    header: *const Header,
    length: usize,

    pub fn init(font: []const u8) !Psf1 {
        if (font.len < @sizeOf(Header))
            return error.OutOfBounds;

        var ret: Psf1 = undefined;

        ret.data = font;
        ret.header = @as(*const Header, @ptrCast(@alignCast(ret.data)));
        if (ret.header.magic != 0x0436)
            return error.InvalidMagic;

        ret.length = if (ret.header.flags == 1) 512 else 256;

        const last_glyph_offset = @sizeOf(Header) + @as(usize, @intCast(ret.header.height)) * ret.length;
        if (font.len < last_glyph_offset)
            return error.OutOfBounds;

        return ret;
    }

    pub fn getChar(self: *const Psf1, char: u8) ![]const u8 {
        return getIndex(self, char);
    }

    pub fn getIndex(self: *const Psf1, index: usize) ![]const u8 {
        if (index >= self.length)
            return error.OutOfBounds;

        const offset = @sizeOf(Header) + index * self.header.height;
        return self.data[offset..(offset + self.header.height)];
    }
};

pub const Psf2 = struct {
    pub const Header = struct {
        magic: u32 = 0x864ab572,
        version: u32,
        header_size: u32,
        flags: u32,
        length: u32,
        glyph_size: u32,
        height: u32,
        width: u32,
    };

    data: []const u8,
    header: *align(1) const Header,
    unicode: std.StringArrayHashMap(usize),

    pub fn init(font: []const u8, allocator: std.mem.Allocator) !Psf2 {
        var ret: Psf2 = undefined;

        ret.data = font;
        ret.header = @as(*align(1) const Header, @ptrCast(ret.data));
        if (ret.header.magic != 0x864ab572)
            return error.InvalidMagic;

        ret.unicode = std.StringArrayHashMap(usize).init(allocator);

        const last_glyph_offset = ret.header.header_size + ret.header.glyph_size * ret.header.length;
        if (font.len < last_glyph_offset)
            return error.OutOfBounds;

        if (ret.header.flags == 1) {
            const table = ret.data[last_glyph_offset..];
            var table_iter = std.mem.splitScalar(u8, table, 0xFF);
            var i: usize = 0;
            while (table_iter.next()) |entry| : (i += 1) {
                var j: usize = 0;
                while (j < entry.len) : (j += 1) {
                    const len: usize = std.unicode.utf8ByteSequenceLength(entry[j]) catch continue;
                    const key = entry[j..][0..len];
                    try ret.unicode.put(key, i);
                    j += len;
                }
            }
        }

        return ret;
    }

    pub fn deinit(self: *Psf2) void {
        self.unicode.deinit();
    }

    pub fn getChar(self: *const Psf2, char: u21) ![]const u8 {
        var buf = [1]u8{0} ** 4;
        const len: usize = try std.unicode.utf8Encode(char, buf[0..]);
        return self.getUnicode(buf[0..len]);
    }

    pub fn getUnicode(self: *const Psf2, sequence: []u8) ![]const u8 {
        const index: usize = self.unicode.get(sequence) orelse if (std.ascii.isASCII(@as(u8, @intCast(try std.unicode.utf8Decode(sequence)))) and sequence.len == 1)
            sequence[0]
        else
            undefined;

        return self.getIndex(index);
    }

    pub fn getIndex(self: *const Psf2, index: usize) ![]const u8 {
        if (index >= self.header.length)
            return error.OutOfBounds;

        const offset = self.header.header_size + index * self.header.glyph_size;
        return self.data[offset..(offset + self.header.glyph_size)];
    }
};
