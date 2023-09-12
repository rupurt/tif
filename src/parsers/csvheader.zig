const std = @import("std");

/// TODO: add docs
pub const CsvHeaderParser = struct {
    /// Initialize a new parser
    pub fn init(allocator: std.mem.Allocator) !*CsvHeaderParser {
        var parser = try allocator.create(CsvHeaderParser);
        parser.* = .{};
        return parser;
    }

    pub fn sniff(parser: *CsvHeaderParser, allocator: std.mem.Allocator, file: std.fs.File) ![]const u8 {
        var buffer = try allocator.alloc(u8, 1024);
        var read = try file.read(buffer);
        if (read == 0) {
            return null;
        }
        var header = try parser.parse(allocator, buffer[0..read]);
        return header;
    }
};
