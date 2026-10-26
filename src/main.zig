const std = @import("std");
const Io = std.Io;

const TableFieldEntry = @import("ZigTable").TableFieldEntry;
const ZigTable = @import("ZigTable").ZigTable;
const Formatting = @import("ZigTable").Formatting;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const Table = ZigTable(&.{
        .{
            .field_type = []const u8,
            .id = "name",
            .display_name = "Name",
            .fmt_type = .string,
            .padding = 8,
            .alignment = .left,
        },
        .{
            .field_type = u8,
            .id = "age", 
            .display_name = "Age",
            .fmt_type = .number, 
            .padding = 3,
            .alignment = .right,
        },
    });

    var table: Table = .init(allocator);
    defer table.deinit();

    _ = try table.addRecord("Austin", .{.name = "Austin", .age = 27});
    _ = try table.addRecord("Kayla", .{.name = "Kayla", .age = 27});
    _ = try table.addRecord("A", .{.name = "mynammajeff", .age = 27});

    var file_buf: [1024]u8 = @splat(0);
    try table.build();
    try table.printStdout(io, &file_buf);
}
