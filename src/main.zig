const std = @import("std");
const clap = @import("clap");

const evaluation = @import("evaluation.zig");
const index = @import("index.zig");

const debug = std.debug;
const io = std.io;
const process = std.process;
const Blake3 = std.crypto.hash.Blake3;

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help              Display this help and exit.
        \\-b, --buffer <BUFFER>   Number of bytes to use as a buffer. Default: 4096
        \\<FILE1>                 The base file
        \\<FILE2>                 The file to compare
        \\
    );
    const parsers = comptime .{
        .BUFFER = clap.parsers.int(u32, 10),
        .FILE1 = clap.parsers.string,
        .FILE2 = clap.parsers.string,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    // arg validation
    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }
    if (res.positionals.len != 2) {
        return clap.usage(std.io.getStdErr().writer(), clap.Help, &params);
    }
    const buffer_size: u32 = if (res.args.buffer) |l| l else 4096;

    // free all memory on exit
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file1_path: []const u8 = res.positionals[0];
    std.debug.print("file1: {s}\n", .{file1_path});
    const file2_path: []const u8 = res.positionals[1];
    std.debug.print("file2: {s}\n", .{file2_path});

    // create shared cache dirs
    var eval_ctx = try evaluation.Context.init(allocator, file1_path, file2_path);
    try eval_ctx.makeCache();
    var idx = try index.FSIndex.init();
    try idx.makeCache();

    // file1
    var file1 = try std.fs.cwd().openFile(file1_path, .{});
    defer file1.close();

    const file1_stat = try file1.stat();
    std.debug.print("file1 size: {d} bytes\n", .{file1_stat.size});

    var hash1 = Blake3.init(.{});
    var hash1_out: [Blake3.digest_length]u8 = undefined;

    var buf_reader1 = std.io.bufferedReader(file1.reader());
    var in_stream1 = buf_reader1.reader();

    var buf1 = try allocator.alloc(u8, buffer_size);
    while (true) {
        const bytes_read = try in_stream1.read(buf1);
        hash1.update(buf1[0..bytes_read]);
        if (bytes_read == 0) {
            break;
        }
    }
    hash1.final(hash1_out[0..]);
    std.debug.print("file1 sha256: {s}\n", .{std.fmt.fmtSliceHexLower(&hash1_out)});

    // file2
    var file2 = try std.fs.cwd().openFile(file2_path, .{});
    defer file2.close();

    const file2_stat = try file1.stat();
    std.debug.print("file2 size: {d} bytes\n", .{file2_stat.size});

    var hash2 = Blake3.init(.{});
    var hash2_out: [Blake3.digest_length]u8 = undefined;
    var buf_reader2 = std.io.bufferedReader(file2.reader());
    var in_stream2 = buf_reader2.reader();

    var buf2: [4096]u8 = undefined;
    while (true) {
        const bytes_read = try in_stream2.read(&buf2);
        hash2.update(buf2[0..bytes_read]);
        if (bytes_read == 0) {
            break;
        }
    }
    hash2.final(hash2_out[0..]);
    std.debug.print("file2 sha256: {s}\n", .{std.fmt.fmtSliceHexLower(&hash2_out)});
}
