const std = @import("std");

const Blake3 = std.crypto.hash.Blake3;

/// The context of an evaluation run
pub const Context = struct {
    id: [Blake3.digest_length]u8,
    path: []const u8,
    file1_path: []const u8,
    file2_path: []const u8,

    pub fn init(allocator: std.mem.Allocator, file1_path: []const u8, file2_path: []const u8) !Context {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        var prng = std.rand.DefaultPrng.init(seed);
        var bytes: [1024]u8 = undefined;
        prng.random().bytes(&bytes);
        var id_hash: [Blake3.digest_length]u8 = undefined;
        Blake3.hash(&bytes, &id_hash, .{});

        var eval_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{
            ".tif/evaluations",
            std.fmt.fmtSliceHexLower(&id_hash),
        });

        return Context{
            .id = id_hash,
            .path = eval_path,
            .file1_path = file1_path,
            .file2_path = file2_path,
        };
    }

    pub fn makeCache(self: *Context) !void {
        try std.fs.cwd().makePath(self.path);
    }
};
