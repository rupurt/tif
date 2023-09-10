const std = @import("std");
const clap = @import("clap");

const debug = std.debug;
const io = std.io;
const process = std.process;

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help       Display this help and exit.
        \\<FILE1>          The base file
        \\<FILE2>          The file to compare
        \\
    );
    const parsers = comptime .{
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

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }
    if (res.positionals.len != 2) {
        return clap.usage(std.io.getStdErr().writer(), clap.Help, &params);
    }

    // line buffer
    const line_buffer_size = 1024;
    std.debug.print("line buffer size: {d}\n", .{line_buffer_size});

    // file1
    const file1_path: []const u8 = res.positionals[0];
    std.debug.print("file1: {s}\n", .{file1_path});

    var file1 = try std.fs.cwd().openFile(file1_path, .{});
    defer file1.close();

    var buf_reader1 = std.io.bufferedReader(file1.reader());
    var in_stream1 = buf_reader1.reader();

    var buf1: [line_buffer_size]u8 = undefined;
    while (try in_stream1.readUntilDelimiterOrEof(&buf1, '\n')) |line| {
        std.debug.print("line: {s}\n", .{line});
    }

    // file1
    const file2_path: []const u8 = res.positionals[1];
    std.debug.print("file2: {s}\n", .{file2_path});

    var file2 = try std.fs.cwd().openFile(file2_path, .{});
    defer file2.close();

    var buf_reader2 = std.io.bufferedReader(file2.reader());
    var in_stream2 = buf_reader2.reader();

    var buf2: [line_buffer_size]u8 = undefined;
    while (try in_stream2.readUntilDelimiterOrEof(&buf2, '\n')) |line| {
        std.debug.print("line: {s}\n", .{line});
    }
}
