const std = @import("std");

const fmt = std.fmt;
const io = std.io;
const mem = std.mem;

/// A top down recursive decent CSV parser
pub const CsvRecordParser = struct {
    null_record: *CsvNullRecord,
    parse_result: *CsvParseResult,
    header: *CsvHeader,
    current_record: *CsvRecord,

    /// Initialize a new parser
    pub fn init(allocator: mem.Allocator, columns_buffer: *CsvColumnsBuffer) !*CsvRecordParser {
        var null_record = try CsvNullRecord.init(allocator);
        var parse_result = try CsvParseResult.init(allocator, null_record);
        var header = try CsvHeader.init(allocator, null_record);
        var record_idx: u32 = 0;
        var current_record = try CsvRecord.init(allocator, columns_buffer, record_idx);

        var parser = try allocator.create(CsvRecordParser);
        parser.* = .{
            .null_record = null_record,
            .parse_result = parse_result,
            .header = header,
            .current_record = current_record,
        };

        return parser;
    }

    /// Process the next byte enforcing the current valid state
    pub fn next(self: *CsvRecordParser, allocator: mem.Allocator, c: u8) !*CsvParseResult {
        var end_of_record = self.current_record.next(c);
        if (end_of_record) {
            var record_str = try self.current_record.to_string(allocator);
            _ = try io.getStdErr().write(try fmt.allocPrint(
                allocator,
                "{s}\n",
                .{record_str},
            ));
            self.current_record.next_record();
        }

        return self.parse_result;
    }
};

/// A CSV record from a file
///
/// Each record is a collection of columns and associated metadata such as it's index
pub const CsvRecord = struct {
    columns_buffer: *CsvColumnsBuffer,
    idx: u64,

    /// Initialize a new record
    pub fn init(allocator: mem.Allocator, columns_buffer: *CsvColumnsBuffer, idx: u64) !*CsvRecord {
        var record = try allocator.create(CsvRecord);
        record.* = .{ .columns_buffer = columns_buffer, .idx = idx };

        return record;
    }

    /// Parse the next character for this record and return true if the record is complete
    pub fn next(self: *CsvRecord, c: u8) bool {
        return self.columns_buffer.next(c);
    }

    /// TODO: add docs
    pub fn next_record(self: *CsvRecord) void {
        self.columns_buffer.reset();
        self.idx = self.idx + 1;
    }

    /// Join columns separated by the delimiter `,` into a string buffer
    pub fn to_string(self: *CsvRecord, allocator: mem.Allocator) ![]u8 {
        var columns_buffer = self.columns_buffer;
        var column_indexes = columns_buffer.indexes;
        var column_values = columns_buffer.values;

        var num_cols = column_indexes.len;
        var buf = try allocator.alloc(u8, column_values.len + num_cols);
        var buf_stream = io.fixedBufferStream(buf);

        // for (self.columns.items, 0..) |col, idx| {
        //     if (idx > 0) {
        //         _ = try buf_stream.write(",");
        //     }
        //     _ = try buf_stream.write(col.buffer);
        // }
        _ = try buf_stream.write(column_values);

        return try fmt.allocPrint(
            allocator,
            (
                \\---RECORD---
                \\delimited record: {s}
                \\packed record:    {s}
                \\record index:     {d}
                \\columns:          {d}
                \\---END RECORD---
                \\
            ),
            .{ buf_stream.buffer, column_values, self.idx, num_cols },
        );
    }
};

/// Represents the absence of a CSV record
pub const CsvNullRecord = struct {
    /// Initialize a null record instance
    pub fn init(allocator: mem.Allocator) !*CsvNullRecord {
        var record = try allocator.create(CsvNullRecord);
        record.* = .{};
        return record;
    }

    /// Return an empty string
    pub fn to_string(self: *CsvNullRecord, allocator: mem.Allocator) ![]u8 {
        _ = allocator;
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
    pub fn init(allocator: mem.Allocator, null_record: *CsvNullRecord) !*CsvHeader {
        var header = try allocator.create(CsvHeader);
        header.* = .{ .null = null_record };
        return header;
    }

    /// Delegate to the tagged to_string/0 method
    pub fn to_string(self: *CsvHeader, allocator: mem.Allocator) ![]u8 {
        switch (self.*) {
            inline else => |*case| return case.*.to_string(allocator),
        }
    }
};

/// TODO: add docs
pub const CsvParseResult = union(enum) {
    null: *CsvNullRecord,
    record: *CsvRecord,

    /// Initialize a new tagged union parse result
    pub fn init(allocator: mem.Allocator, null_record: *CsvNullRecord) !*CsvParseResult {
        var parse_result = try allocator.create(CsvParseResult);
        parse_result.* = .{ .null = null_record };
        return parse_result;
    }
};

/// Wrapper around a slice of bytes containing CSV columns for a record
pub const CsvColumnsBuffer = struct {
    values_buffer: []u8,
    values: []u8,
    indexes_buffer: []u32,
    indexes: []u32,

    /// Initialize a new CSV columns buffer
    pub fn init(allocator: mem.Allocator, max_columns: u32, buffer_size: u32) !*CsvColumnsBuffer {
        var values_buffer = try allocator.alloc(u8, buffer_size);
        var indexes_buffer = try allocator.alloc(u32, max_columns);
        var csv_columns_buffer = try allocator.create(CsvColumnsBuffer);
        csv_columns_buffer.* = .{ .values_buffer = values_buffer, .values = values_buffer[0..0], .indexes_buffer = indexes_buffer, .indexes = indexes_buffer[0..0] };
        return csv_columns_buffer;
    }

    /// Parse the next character for this record as the last column and return true if the record is complete
    ///
    /// - If the character is a `,` the ending column index is recorded
    /// - If the character is a `\n` the ending column index is recorded
    /// - Otherwise the character is copied into the value slice mask
    pub fn next(self: *CsvColumnsBuffer, c: u8) bool {
        var end_of_record = false;
        const val_len: u32 = @intCast(self.values.len);
        const idx_len: u32 = @intCast(self.indexes.len);

        if (c == ',') {
            // std.debug.print("------- end of column at index {d} - delimiter `,`\n", .{val_len});
            self.indexes.len = idx_len + 1;
            self.indexes[idx_len] = @max(0, val_len);
        } else if (c == '\n') {
            // std.debug.print("------- end of column at index {d} - delimiter `\\n`\n", .{val_len});
            self.indexes.len = idx_len + 1;
            self.indexes[idx_len] = @max(0, val_len);
            end_of_record = true;
        } else {
            self.values.len = val_len + 1;
            self.values[val_len] = c;
        }

        return end_of_record;
    }

    /// Shrink the slice masks to represent an empty record
    pub fn reset(self: *CsvColumnsBuffer) void {
        self.values = self.values_buffer[0..0];
        self.indexes = self.indexes_buffer[0..0];
    }
};
