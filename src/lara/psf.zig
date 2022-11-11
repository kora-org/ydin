const std = @import("std");

const Psf1 = struct {
    pub const Header = struct {
        magic: u16 = 0x0436,
        flags: u8,
        height: u8,
    };

    pub fn init(font: []const u8) Header {
        return @ptrCast(Header, font);
    }
};

const Psf2 = struct {
    magic: u32 = 0x864ab572,
    version: u32,
    headerSize: u32,
    flags: u32,
    glyphs: u32,
    glyphBytes: u32,
    height: u32,
    width: u32,
};
