const std = @import("std");
const SmartSoA = @import("SmartSoA").SmartSoA;

pub fn ZigTable(comptime Column: type) type {
    return struct {
        const Self = @This();
        
        allocator: std.mem.Allocator,
        rows: std.ArrayList(Column) = .empty,
        table_data: SmartSoA(Column) = undefined,
        table_writer: std.Io.Writer.Allocating = undefined,
        row_writer: std.Io.Writer.Allocating = undefined,

        pub fn init(allocator: std.mem.Allocator) Self {
            var self: Self = .{.allocator = allocator};

            self.table_data = .init();
            self.table_writer = .init(allocator);
            self.row_writer = .init(allocator);
            return self;
        }

        pub fn deinit(self: *Self) void {
            self.rows.deinit(self.allocator);
            self.table_data.deinit(self.allocator);
            self.table_writer.deinit();
            self.row_writer.deinit();
        }

        pub fn addRow(self: *Self, row: Column) !void {
            try self.table_data.append(self.allocator, row);
        }

        pub fn fmt(self: *Self) ![]u8 {
            const table_writer = &self.table_writer.writer;
            const col = self.table_data.allItems();
            
            for(0..self.table_data.len) |i| {
                self.row_writer.clearRetainingCapacity();
                inline for(std.meta.fields(Column)) |field| {
                    
                }
            }
            
            for(self.rows.items) |row| {
                inline for(fields) |field| {
                    const T = @TypeOf(@field(row, field.name));
                    const val: T = @field(row, field.name);

                    try table_writer.print("{s}", .{val});
                }
                
                _ = try table_writer.write("\n");
            }

            return self.table_writer.written();
        }
    };
}

// fn TableContents(comptime Column: type) type {
//     const Contents = GenerateContents(Column);
//     return struct {
//         const Self = @This();
//         allocator: std.mem.Allocator,
//         contents: Contents = undefined,

//         fn init(allocator: std.mem.Allocator) Self {
//             var self: Self = .{.allocator = allocator};
//             inline for(std.meta.fields(Contents)) |field| 
//                 @field(&self.contents, field.name) = .empty;

//             return self;
//         }

//         fn deinit(self: *Self) void {
//             inline for(std.meta.fields(Contents)) |field| 
//                 @field(&self.contents, field.name) = .deinit(self.allocator);
//         }

        
//     };
// }

// fn GenerateContents(comptime Column: type) type {
//     const fields = std.meta.fields(Column);
    
//     var names: [fields.len][]const u8 = undefined;
//     var types: [fields.len]type = undefined;
//     var attrs: [fields.len]std.builtin.Type.StructField.Attributes = undefined;
    
//     for (fields, 0..) |field, i| {
//         const T = @FieldType(Column, field.name);
        
//         names[i] = field.name;
//         types[i] = std.ArrayList(T);
//         attrs[i] = .{};
//     }
    
//     return @Struct(
//         .auto,
//         null,
//         &names,
//         &types,
//         &attrs,
//     );
// }
