const std = @import("std");
const clap = @import("clap");

const evaluation = @import("evaluation.zig");
const csvrecord = @import("parsers/csvrecord.zig");

const heap = std.heap;
const io = std.io;

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                      Display this help and exit.
        \\-r, --readbuffer <READBUFFER>   Number of bytes to use as a buffer. Default: 65536
        \\-c, --colbuffer  <COLBUFFER>    Number of bytes to use as a column buffer. Default: 4096
        \\-m, --maxcolumns <MAXCOLUMNS>   Maximum number of columns in a record. Default: 512
        \\<PATH1>                         The base path
        \\<PATH1>                         The path to compare
        \\
    );
    const parsers = comptime .{
        .READBUFFER = clap.parsers.int(u32, 10),
        .COLBUFFER = clap.parsers.int(u32, 10),
        .MAXCOLUMNS = clap.parsers.int(u32, 10),
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
        return clap.help(io.getStdErr().writer(), clap.Help, &params, .{});
    }
    if (res.positionals.len != 2) {
        return clap.usage(io.getStdErr().writer(), clap.Help, &params);
    }
    const read_buffer_size = if (res.args.readbuffer) |l| l else @as(u32, 65536);
    const col_buffer_size = if (res.args.colbuffer) |l| l else @as(u32, 4096);
    const max_columns = if (res.args.maxcolumns) |l| l else @as(u32, 512);

    // free all memory on exit
    var arena = heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // create a parser and context for each path
    var path1_cols_buffer = try csvrecord.CsvColumnsBuffer.init(allocator, max_columns, col_buffer_size);
    var path1_parser = try csvrecord.CsvRecordParser.init(allocator, path1_cols_buffer);
    var path1_ctx = try evaluation.ContextPath.init(allocator, res.positionals[0], read_buffer_size, path1_parser);

    var path2_cols_buffer = try csvrecord.CsvColumnsBuffer.init(allocator, max_columns, col_buffer_size);
    var path2_parser = try csvrecord.CsvRecordParser.init(allocator, path2_cols_buffer);
    var path2_ctx = try evaluation.ContextPath.init(allocator, res.positionals[1], read_buffer_size, path2_parser);

    // create and run an evaluation
    var eval_ctx = try evaluation.Context.init(
        allocator,
        path1_ctx,
        path2_ctx,
    );
    try eval_ctx.*.run(allocator);
}
