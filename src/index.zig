const std = @import("std");

/// TODO: add docs
pub const FSIndex = struct {
    pub fn init() !FSIndex {
        return FSIndex{};
    }

    pub fn makeCache(self: *FSIndex) !void {
        _ = self;
        try std.fs.cwd().makePath(".tif/index");
    }
};
