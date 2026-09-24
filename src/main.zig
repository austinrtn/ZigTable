const std = @import("std");
const Io = std.Io;

const ZigTable = @import("ZigTable").ZigTable;

pub fn main(init: std.process.Init) !void {
    var buf: [1028]u8 = undefined;
    var writer = std.Io.File.Writer.init(.stdout(), init.io, &buf);
    const stdout = &writer.interface;
    
    const Col = struct { name: []const u8, age: []const u8 };
    var table: ZigTable(Col) = .init(init.gpa);
    defer table.deinit();

    try table.addRow(.{.name = "Austin", .age = "27"});
    try table.addRow(.{.name = "Kayla", .age = "27.5"});

    const txt = try table.fmt();
    try stdout.print("{s}", .{txt});
    try stdout.flush();
}
