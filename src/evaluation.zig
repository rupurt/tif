const std = @import("std");

const csvrecord = @import("parsers/csvrecord.zig");

const Blake3 = std.crypto.hash.Blake3;

/// The context of an evaluation instance
pub const Context = struct {
    id: []u8,
    path: []const u8,
    path1: []const u8,
    path2: []const u8,
    buffer_size: u32,

    /// Initialize an evaluation context by generating a unique id and building a
    /// path for the cache directory
    pub fn init(allocator: std.mem.Allocator, path1: []const u8, path2: []const u8, buffer_size: u32) !*Context {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        var prng = std.rand.DefaultPrng.init(seed);
        var bytes: [1024]u8 = undefined;
        prng.random().bytes(&bytes);
        var id_hash = try allocator.alloc(u8, Blake3.digest_length);
        Blake3.hash(&bytes, id_hash, .{});

        var ctx_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{
            ".tif/evaluations",
            std.fmt.fmtSliceHexLower(id_hash),
        });

        var ctx = try allocator.create(Context);
        ctx.* = .{
            .id = id_hash,
            .path = ctx_path,
            .path1 = path1,
            .path2 = path2,
            .buffer_size = buffer_size,
        };

        return ctx;
    }

    /// Run the evaluation context
    ///
    /// 1. Create a cache directory for the evaluation instance
    /// 2. Sniff `path1` & `path2` headers
    /// 3. Create `path1` index
    /// 4. Create `path2` index
    pub fn run(self: *Context, allocator: std.mem.Allocator) !void {
        try makeCachePath(self.path);

        const path1_idx = Index{ .fs = PathIndex{ .path = self.path1, .eval_ctx = self } };
        try path1_idx.create(allocator);

        const path2_idx = Index{ .fs = PathIndex{ .path = self.path2, .eval_ctx = self } };
        try path2_idx.create(allocator);
    }
};

/// Create the cache directory for an evaluation instance
fn makeCachePath(ctx_path: []const u8) !void {
    try std.fs.cwd().makePath(ctx_path);
}

/// Represents the indexed records of the contents in a path
pub const PathIndex = struct {
    path: []const u8,
    eval_ctx: *Context,

    pub fn create(self: *const PathIndex, allocator: std.mem.Allocator) !void {
        var file = try std.fs.cwd().openFile(self.path, .{});
        defer file.close();

        const file_stat = try file.stat();
        _ = try std.io.getStdOut().write(try std.fmt.allocPrint(
            allocator,
            "file size bytes: {d}, inode: {d}, ctime: {d}, mtime: {d}\n",
            .{ file_stat.size, file_stat.inode, file_stat.ctime, file_stat.mtime },
        ));

        var hash = Blake3.init(.{});
        var hash_out: [Blake3.digest_length]u8 = undefined;

        var parser = try csvrecord.CsvRecordParser.init(allocator, self.eval_ctx.buffer_size);

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf = try allocator.alloc(u8, self.eval_ctx.buffer_size);
        // read bytes from file into a buffer until EOF
        while (true) {
            const bytes_read = try in_stream.read(buf);
            if (bytes_read == 0) {
                break;
            }

            // update hash with bytes read
            hash.update(buf[0..bytes_read]);

            // parse tabular structure from bytes read
            for (buf[0..bytes_read]) |c| {
                var parse_result = try parser.next(allocator, c);
                _ = parse_result;
            }
        }

        hash.final(hash_out[0..]);
        _ = try std.io.getStdOut().write(try std.fmt.allocPrint(
            allocator,
            "blake3 hash: {s}\n",
            .{std.fmt.fmtSliceHexLower(&hash_out)},
        ));
        _ = try std.io.getStdOut().write(try std.fmt.allocPrint(
            allocator,
            "headers: {s}\n",
            .{parser.header.to_string()},
        ));
    }
};

/// TODO: add docs
pub const Index = union(enum) {
    fs: PathIndex,

    /// TODO: add docs
    pub fn create(self: *const Index, allocator: std.mem.Allocator) !void {
        switch (self.*) {
            inline else => |*case| try case.create(allocator),
        }
    }
};

/// Hash the record from the joined literal string buffer of bytes from each column
fn hashRecord(record: *csvrecord.CsvRecord) []u8 {
    _ = record;
    var hash = [_]u8{'c'};
    return hash;
}
