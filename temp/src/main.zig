const std = @import("std");
const Io = std.Io;

const temp = @import("temp");

pub fn main(init: std.process.Init) !void {
    _ = init;

    //const col_name = "Age";
    const val = 323123;
    const T = @TypeOf(val);
    const t_info = @typeInfo(T);

    //std.debug.print("{any}", .{t_info});
    var char: []const u8 = "";
    var string_val: []const u8 = "";
    var type_buf: [256]u8 = undefined;
    var val_buf: [256]u8 = undefined;
    var space_buf: [256]u8 = undefined;
    var line_buf: [1024]u8 = undefined;

    switch(t_info) {
        .int, .comptime_int => {
            char = "d";  
            string_val = try std.fmt.bufPrint(&val_buf, "{d}", .{val}); 
        }, 
        else => unreachable,
    }

    const symbol = try std.fmt.bufPrint(&type_buf, "{{{s}:", .{char});
    const space = try std.fmt.bufPrint(&space_buf, "{d}", .{string_val.len});
    const line = try std.fmt.bufPrint(&line_buf, "{s}{s}}}", .{symbol, space});

    std.debug.print("{s}", .{line});
}

