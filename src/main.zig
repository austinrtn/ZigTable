const std = @import("std");
const Io = std.Io;

const ZigTable = @import("ZigTable").ZigTable;

pub fn main(init: std.process.Init) !void {
    var buf: [1028]u8 = undefined;
    var writer = std.Io.File.Writer.init(.stdout(), init.io, &buf);
    const stdout = &writer.interface;
    
    const field_count = 5;
    const str_len = 3;
    const col_count = 5;
    const Col = Column(field_count);
    
    var table: ZigTable(Col) = .init(init.gpa);
    defer table.deinit();

    var cols: std.ArrayList(Col) = .empty;
    defer cols.deinit(init.gpa);
    try cols.resize(init.gpa, col_count);
    
    for(cols.items) |*col| {
        col.* = try initColumn(field_count, str_len, init.gpa, init.io);
        _ = try table.addRow(col.*);
    }
    defer for(cols.items) |*col| deinitColumn(field_count, col, init.gpa); 
    
    try table.build();
    const txt = table.getTableTxt();
    try stdout.print("{s}", .{txt});
    try stdout.flush();
}

fn Column(comptime field_count: usize) type {
    var names: [field_count][]const u8 = undefined;
    var types: [field_count]type = undefined;
    var attrs: [field_count]std.builtin.Type.StructField.Attributes = undefined;
    
    for (0..field_count) |i| {
        const name = std.fmt.comptimePrint("field_{d}", .{i});
        names[i] = name;
        types[i] = []const u8;
        attrs[i] = .{};
    }
    
    return @Struct(
        .auto,
        null,
        &names,
        &types,
        &attrs,
    );
}

fn initColumn(comptime field_count: usize, comptime str_len: usize, allocator: std.mem.Allocator, io: Io) !Column(field_count) {
    var col: Column(field_count) = undefined;
    var seed: u64 = undefined;
    io.random(std.mem.asBytes(&seed));

    var random = std.Random.Xoshiro256.init(seed);
    const rand = random.random();
    
    inline for(std.meta.fields(@TypeOf(col))) |field| {
        const string = blk: {
            var str: [str_len]u8 = undefined;
            for(&str) |*char| {
                char.* = rand.int(u8);
            }
            break :blk str;
        };
        
        @field(col, field.name) = try allocator.dupe(u8, &string);
    }

    return col;
}

fn deinitColumn(comptime field_count: usize, column: *Column(field_count), allocator: std.mem.Allocator) void {
    inline for(std.meta.fields(@TypeOf(column.*))) |field| {
        allocator.free(@field(column.*, field.name));
    }
}