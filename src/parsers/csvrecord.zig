const std = @import("std");

/// A top down LL(1) recursive decent CSV parser
pub const CsvRecordParser = struct {
    null_record: *CsvNullRecord,
    parse_result: *CsvParseResult,
    header: *CsvHeader,
    current_record: *CsvRecord,

    /// Initialize a new parser
    pub fn init(allocator: std.mem.Allocator, buffer_size: u32) !*CsvRecordParser {
        var null_record = try CsvNullRecord.init(allocator);
        var parse_result = try CsvParseResult.init(allocator, null_record);
        var header = try CsvHeader.init(allocator, null_record);
        var record_idx: u32 = 0;
        var current_record = try CsvRecord.init(allocator, buffer_size, record_idx);

        var parser = try allocator.create(CsvRecordParser);
        parser.* = .{
            .null_record = null_record,
            .parse_result = parse_result,
            .header = header,
            .current_record = current_record,
        };

        return parser;
    }

    /// Process the next byte enforcing to the current valid state
    pub fn next(self: *CsvRecordParser, allocator: std.mem.Allocator, c: u8) !*CsvParseResult {
        // _ = try std.io.getStdOut().write(try std.fmt.allocPrint(
        //     allocator,
        //     "{c}",
        //     .{c},
        // ));

        try self.current_record.next(allocator, c);

        if (c == '\n') {
            _ = try std.io.getStdOut().write(try std.fmt.allocPrint(
                allocator,
                "... processed record {d} - create a new record\n",
                .{self.current_record.idx},
            ));
            self.current_record.reset(self.current_record.idx + 1);
        }

        return self.parse_result;
    }
};

/// Represents a CSV record from a file
///
/// Each record is a collection of columns and associated metadata such as it's index
pub const CsvRecord = struct {
    columns: std.ArrayList(CsvColumn),
    buffer_size: u32,
    idx: u64,

    /// Initialize a new record
    pub fn init(allocator: std.mem.Allocator, buffer_size: u32, idx: u64) !*CsvRecord {
        var columns = std.ArrayList(CsvColumn).init(allocator);
        var record = try allocator.create(CsvRecord);
        record.* = .{ .columns = columns, .buffer_size = buffer_size, .idx = idx };

        return record;
    }

    /// Parse the next character for this record
    ///
    /// - If the character is a `,` then a new column is created
    /// - Otherwise the character is delegated to the current column
    pub fn next(self: *CsvRecord, allocator: std.mem.Allocator, c: u8) !void {
        _ = allocator;
        _ = c;
        _ = self;
        // if (c == ',') {
        //     _ = try std.io.getStdOut().write(try std.fmt.allocPrint(
        //         allocator,
        //         "------- got , - need new csv column\n",
        //         .{},
        //     ));
        // } else {
        //     var column = CsvColumn.init(allocator);
        //     _ = column;
        // }

        // var current_column: *CsvColumn = undefined;
        //
        // _ = try std.io.getStdOut().write(try std.fmt.allocPrint(
        //     allocator,
        //     "------- in CsvRecord - current column idx: {}\n",
        //     .{current_column},
        // ));
    }

    /// TODO: add docs
    pub fn reset(self: *CsvRecord, idx: u64) void {
        self.idx = idx;
    }

    /// Join columns into a string buffer separated by the delimiter `,`
    pub fn to_string(self: *CsvRecord) []const u8 {
        _ = self;
        return "todo: csv record...";
    }
};

/// Represents the absence of a CSV record
pub const CsvNullRecord = struct {
    /// Initialize a null record instance
    pub fn init(allocator: std.mem.Allocator) !*CsvNullRecord {
        var record = try allocator.create(CsvNullRecord);
        record.* = .{};
        return record;
    }

    /// Return an empty string
    pub fn to_string(self: *CsvNullRecord) []const u8 {
        _ = self;
        return "";
    }
};

/// Represents the header record of a CSV
///
/// When headers are present the union is tagged with .record. When headers are
/// absent it is tagged with .null
pub const CsvHeader = union(enum) {
    null: *CsvNullRecord,
    record: *CsvRecord,

    /// Initialize a new tagged union header
    pub fn init(allocator: std.mem.Allocator, null_record: *CsvNullRecord) !*CsvHeader {
        var header = try allocator.create(CsvHeader);
        header.* = .{ .null = null_record };
        return header;
    }

    /// Delegate to the tagged to_string/0 method
    pub fn to_string(self: *CsvHeader) []const u8 {
        switch (self.*) {
            inline else => |*case| return case.*.to_string(),
        }
    }
};

/// TODO: add docs
pub const CsvParseResult = union(enum) {
    null: *CsvNullRecord,
    record: *CsvRecord,

    /// Initialize a new tagged union parse result
    pub fn init(allocator: std.mem.Allocator, null_record: *CsvNullRecord) !*CsvParseResult {
        var parse_result = try allocator.create(CsvParseResult);
        parse_result.* = .{ .null = null_record };
        return parse_result;
    }
};

const COLUMN_BUFFER_SIZE: u32 = 1024;

/// Represents a column within a record
pub const CsvColumn = struct {
    buffer: []u8,
    idx: u64,

    /// Initialize a new column
    pub fn init(allocator: std.mem.Allocator, idx: u64) !*CsvColumn {
        var buffer = try allocator.alloc([]u8, COLUMN_BUFFER_SIZE);
        var col = allocator.create(CsvColumn);
        col.* = .{ .buffer = buffer, .idx = idx };
        return col;
    }
};
