const std = @import("std");

/// TODO: add docs
pub const Blake3 = struct {};

/// TODO: add docs
pub const Hasher = union(enum) {
    blake3: Blake3,

    // pub fn update(self: *Hasher, data: []const u8) ![]const u8 {
    //     return std.mem.hash(self.blake3, data);
    // }
};
