const limine = @import("limine");
const arch = @import("../x86_64.zig");
const log = @import("std").log.scoped(.framebuffer);

pub export var framebuffer_request: limine.Framebuffer.Request = .{};
pub var framebuffer_response: limine.Framebuffer.Response = undefined;

/// Address to the framebuffer
pub var address: u64 = 0;
/// Width of the framebuffer in pixels
pub var width: u64 = 0;
/// Height of the framebuffer in pixels
pub var height: u64 = 0;
/// Pitch of the framebuffer in bytes
pub var pitch: u64 = 0;
/// Bits per pixel of the framebuffer
pub var bpp: u16 = 0;
pub var memory_model: MemoryModel = .Rgb;
pub var red_mask_size: u8 = 0;
pub var red_mask_shift: u8 = 0;
pub var green_mask_size: u8 = 0;
pub var green_mask_shift: u8 = 0;
pub var blue_mask_size: u8 = 0;
pub var blue_mask_shift: u8 = 0;
pub var edid_size: u64 = 0;
pub var edid: ?[]const u8 = null;

pub fn init() void {
    if (framebuffer_request.response) |framebuffer| {
        framebuffer_response = framebuffer.*;

        if (framebuffer_response.framebuffer_count > 0) {
            address = framebuffer.getFramebuffers()[0].address;
            width = framebuffer.getFramebuffers()[0].width;
            height = framebuffer.getFramebuffers()[0].height;
            pitch = framebuffer.getFramebuffers()[0].pitch;
            bpp = framebuffer.getFramebuffers()[0].bpp;
            memory_model = @intToEnum(MemoryModel, @enumToInt(framebuffer.getFramebuffers()[0].memory_model));
            red_mask_size = framebuffer.getFramebuffers()[0].red_mask_size;
            red_mask_shift = framebuffer.getFramebuffers()[0].red_mask_shift;
            green_mask_size = framebuffer.getFramebuffers()[0].green_mask_size;
            green_mask_shift = framebuffer.getFramebuffers()[0].green_mask_shift;
            blue_mask_size = framebuffer.getFramebuffers()[0].blue_mask_size;
            blue_mask_shift = framebuffer.getFramebuffers()[0].blue_mask_shift;
            edid_size = framebuffer.getFramebuffers()[0].edid_size;
            edid = framebuffer.getFramebuffers()[0].getEdid();
        }
    }
}

/// Returns a slice of the `address` pointer.
pub fn getSlice(comptime T: type) []T {
    return @intToPtr([*]T, address)[0 .. width * height];
}

pub fn putPixel(x: usize, y: usize, color: u32) !void {
    switch (bpp) {
        24 => getSlice(u24)[x + width * y] = @truncate(u24, color),
        32 => getSlice(u32)[x + width * y] = color,
        else => return error.UnsupportedBpp,
    }
}

pub const MemoryModel = enum(u8) {
    Rgb = 1,
    _,
};
