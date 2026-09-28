const std = @import("std");
const ArrayList = std.ArrayList;
const SmartSoA = @import("SmartSoA").SmartSoA;
const Writer = std.Io.Writer.Allocating;

const ColOption = struct{
    field_name: []const u8,
    T: type, 
    space: usize = 0,
    fmt: []const u8 = "",

    fn init(comptime field_name: []const u8, comptime T: type) ColOption {
        var opt: ColOption = .{.field_name = field_name, .T = T};
        opt.fmt = blk: switch(@typeInfo(T)) {
            .int, comptime_int => break :blk "d",
            else => {
                if(isString(T)) break :blk "{s}"
                else unreachable;
            },
        };
    }
};

fn isString(comptime T: type) bool {
    return switch(@typeInfo(T)) {
        .array => |a| a.child == u8,
        .pointer => |p| switch(p.size) {
            .slice => p.child ==  u8,
            .one => switch(@typeInfo(p.child)) {
                .array => |a| a.child == u8,
                else => false,
            },
            else => false
        },
        else => false
    };
}

pub fn ZigTable(comptime Column: type) type {
    const Soa = SmartSoA(Column);
    const ColField = Soa.InnerFieldEnum;
    _ = ColField;
    
    return struct {
        const Self = @This();
        
        allocator: std.mem.Allocator,
        table_data: Soa = undefined,
        table_writer: Writer = undefined,
        row_queue: ArrayList(usize) = .empty,
        row_writers: ArrayList(Writer) = .empty,

        pub fn init(allocator: std.mem.Allocator) Self {
            var self: Self = .{.allocator = allocator};

            self.table_data = .init();
            self.table_writer = .init(allocator);
            return self;
        }

        pub fn deinit(self: *Self) void {
            const allocator = self.allocator;
            
            for(self.row_writers.items) |*writer| writer.deinit();
            self.row_writers.deinit(allocator);
            self.row_queue.deinit(allocator);
            self.table_data.deinit(allocator);
            self.table_writer.deinit();
        }

        pub fn addRow(self: *Self, row: Column) !usize {
            const idx = self.table_data.len;
            try self.table_data.append(self.allocator, row);
            try self.row_writers.append(self.allocator, .init(self.allocator));
            try self.row_queue.append(self.allocator, idx);

            return idx;
        }

        fn fmtElement(row_writer: *Writer, val: anytype) !void {
            const row_w = &row_writer.writer;
            try row_w.print("{s:8}| ", .{val});
        }

        pub fn build(self: *Self) !void {
            const column_fields = comptime std.meta.fields(Column);
            const table_data = &self.table_data;
            const table_writer = &self.table_writer.writer;
            const row_writers = &self.row_writers;
            const row_queue = &self.row_queue;
            
            self.table_writer.clearRetainingCapacity();
            for(row_writers.items) |*row_writer| row_writer.clearRetainingCapacity();
            
            inline for(column_fields) |field| try table_writer.print("{s:8}| ", .{field.name});
            _ = try table_writer.write("\n");
            
            inline for(column_fields) |field| {
                const field_enum = comptime std.meta.stringToEnum(std.meta.FieldEnum(Column), field.name) orelse unreachable;
                const col_items = table_data.items(field_enum);

                for(0..row_queue.items.len) |i| {
                    const row_writer = &row_writers.items[i];
                    const col_val = col_items[i];
                    try fmtElement(row_writer, col_val);
                }
            }

            for(row_writers.items) |*row_writer| 
                try table_writer.print("{s}\n", .{row_writer.written()});
                
            row_queue.clearRetainingCapacity();
        }

        pub fn getTableTxt(self: *Self) []u8 {
            return self.table_writer.written();
        }
    };
}