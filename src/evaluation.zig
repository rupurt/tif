const std = @import("std");

const csvrecord = @import("parsers/csvrecord.zig");

const fmt = std.fmt;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os;
const rand = std.rand;
const Blake3 = std.crypto.hash.Blake3;

/// The context of an evaluation instance
pub const Context = struct {
    id: []u8,
    path: []const u8,
    path1_ctx: *ContextPath,
    path2_ctx: *ContextPath,

    /// Initialize an evaluation context by generating a unique id and building a
    /// path for the cache directory
    pub fn init(allocator: mem.Allocator, path1_ctx: *ContextPath, path2_ctx: *ContextPath) !*Context {
        var seed: u64 = undefined;
        try os.getrandom(mem.asBytes(&seed));
        var prng = rand.DefaultPrng.init(seed);
        var bytes: [1024]u8 = undefined;
        prng.random().bytes(&bytes);
        var id_hash = try allocator.alloc(u8, Blake3.digest_length);
        Blake3.hash(&bytes, id_hash, .{});

        var ctx_path = try fmt.allocPrint(allocator, "{s}/{s}", .{
            ".tif/evaluations",
            fmt.fmtSliceHexLower(id_hash),
        });

        var ctx = try allocator.create(Context);
        ctx.* = .{
            .id = id_hash,
            .path = ctx_path,
            .path1_ctx = path1_ctx,
            .path2_ctx = path2_ctx,
        };

        return ctx;
    }

    /// Run the evaluation context
    ///
    /// 1. Create a cache directory for the evaluation instance
    /// 2. Sniff `path1` & `path2` headers
    /// 3. Create `path1` index
    /// 4. Create `path2` index
    pub fn run(self: *Context, allocator: mem.Allocator) !void {
        try makeCachePath(self.path);

        const path1_idx = PathIndex{ .fs = FSPathIndex{ .ctx_path = self.path1_ctx } };
        try path1_idx.create(allocator);

        const path2_idx = PathIndex{ .fs = FSPathIndex{ .ctx_path = self.path2_ctx } };
        try path2_idx.create(allocator);
    }
};

/// Create the cache directory for an evaluation instance
fn makeCachePath(ctx_path: []const u8) !void {
    try fs.cwd().makePath(ctx_path);
}

/// Evaluate a path within it's own context
pub const ContextPath = struct {
    path: []const u8,
    read_buffer_size: u32,
    record_parser: *csvrecord.CsvRecordParser,

    /// Initialize a new context path
    pub fn init(allocator: mem.Allocator, path: []const u8, read_buffer_size: u32, record_parser: *csvrecord.CsvRecordParser) !*ContextPath {
        var ctx_path = try allocator.create(ContextPath);
        ctx_path.* = .{
            .path = path,
            .read_buffer_size = read_buffer_size,
            .record_parser = record_parser,
        };

        return ctx_path;
    }
};

/// Path index interface
pub const PathIndex = union(enum) {
    fs: FSPathIndex,

    /// TODO: add docs
    pub fn create(self: *const PathIndex, allocator: mem.Allocator) !void {
        switch (self.*) {
            inline else => |*case| try case.create(allocator),
        }
    }
};

/// Index records on the local file system of the contents in a path
pub const FSPathIndex = struct {
    ctx_path: *ContextPath,

    pub fn create(self: *const FSPathIndex, allocator: mem.Allocator) !void {
        var record_parser = self.ctx_path.record_parser;

        var file = try fs.cwd().openFile(self.ctx_path.path, .{});
        defer file.close();

        var hash = Blake3.init(.{});
        var hash_out: [Blake3.digest_length]u8 = undefined;

        var buf_reader = io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf = try allocator.alloc(u8, self.ctx_path.read_buffer_size);
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
                var parse_result = try record_parser.next(allocator, c);
                _ = parse_result;
            }
        }

        hash.final(hash_out[0..]);
        const file_stat = try file.stat();

        _ = try io.getStdErr().write(try fmt.allocPrint(
            allocator,
            (
                \\file size bytes: {d}
                \\inode:           {d}
                \\ctime:           {d}
                \\mtime:           {d}
                \\blake3 hash:     {s}
                \\
            ),
            .{ file_stat.size, file_stat.inode, file_stat.ctime, file_stat.mtime, fmt.fmtSliceHexLower(&hash_out) },
        ));

        // var header = try record_parser.header.to_string(allocator);
        // _ = try io.getStdErr().write(try fmt.allocPrint(
        //     allocator,
        //     "headers: {s}\n",
        //     .{header},
        // ));
    }
};

/// Hash the record from the joined literal string buffer of bytes from each column
fn hashRecord(record: *csvrecord.CsvRecord) []u8 {
    _ = record;
    var hash = [_]u8{'c'};
    return hash;
}
