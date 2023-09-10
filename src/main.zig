const std = @import("std");
const clap = @import("clap");

const evaluation = @import("evaluation.zig");

const debug = std.debug;
const io = std.io;
const process = std.process;
const Blake3 = std.crypto.hash.Blake3;

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help              Display this help and exit.
        \\-b, --buffer <BUFFER>   Number of bytes to use as a buffer. Default: 4096
        \\<PATH1>                 The base path
        \\<PATH1>                 The path to compare
        \\
    );
    const parsers = comptime .{
        .BUFFER = clap.parsers.int(u32, 10),
        .PATH1 = clap.parsers.string,
        .PATH2 = clap.parsers.string,
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

    // create and run an evaluation
    var eval_ctx = try evaluation.Context.init(
        allocator,
        res.positionals[0],
        res.positionals[1],
        buffer_size,
    );
    try eval_ctx.*.run(allocator);
}
