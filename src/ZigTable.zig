const std = @import("std");
const SmartSoa = @import("SmartSoA").SmartSoA;
const TableFieldMod = @import("TableField.zig");

const testing = std.testing;
const ArrayList = std.ArrayList;
const Writer = std.Io.Writer.Allocating;
const TableField = TableFieldMod.TableField;
const TableFieldEntry = TableFieldMod.TableFieldEntry;

pub fn ZigTable(comptime fields: []const TableFieldEntry) type {
    return struct {
        const Self = @This();
        pub const FieldEnum = getFieldEnum(fields);
        pub const Record = getRecordType(fields, false);
        pub const SetRecord = getRecordType(fields, true);
        pub const RecordId = usize;
        pub const Storage = SmartSoa(Record);
        
        impl: struct {
            allocator: std.mem.Allocator,
            storage: Storage,

            record_map: std.StringHashMap(RecordId) = undefined,
            next_record_id: RecordId = 0,
            heap_record_map_keys: ArrayList([]const u8) = .empty,
            record_writers: ArrayList(Writer) = .empty,
            table_writer: Writer = undefined,
        },

        pub fn init(allocator: std.mem.Allocator) Self {
             var self: Self = .{ .impl = .{ .allocator = allocator, .storage = .init() }};
             self.impl.record_map = .init(allocator);
             self.impl.table_writer = .init(allocator);
             
             return self;
        }

        pub fn deinit(self: *Self) void {
            const impl = &self.impl;
            const allocator = impl.allocator;
            
            impl.storage.deinit(allocator);
            impl.record_map.deinit();
            
            for(impl.record_writers.items) |*writer| writer.deinit();
            for(impl.heap_record_map_keys.items) |*name| allocator.free(name.*);

            impl.record_writers.deinit(allocator);
            impl.heap_record_map_keys.deinit(allocator);
            impl.table_writer.deinit();
        }

        pub fn addRecord(self: *Self, record_name: ?[]const u8, record: Record) !RecordId {
            const impl = &self.impl;
            const id = impl.next_record_id;
            const next_id = try std.math.add(RecordId, id, 1);
            
            const name = if (record_name) |provided|
                try impl.allocator.dupe(u8, provided)
            else
                try std.fmt.allocPrint(impl.allocator, "rec_{d}", .{id});
            errdefer impl.allocator.free(name);

            const res = try impl.record_map.getOrPut(name);
            if (res.found_existing) return error.recordExists;
            errdefer _ = impl.record_map.remove(name);
            res.value_ptr.* = id;

            try impl.storage.append(impl.allocator, record);
            errdefer _ = impl.storage.pop();
            try impl.heap_record_map_keys.append(impl.allocator, name);
            errdefer _ = impl.heap_record_map_keys.pop();

            try impl.record_writers.append(impl.allocator, .init(impl.allocator));
            errdefer _ = impl.record_writers.pop();

            impl.next_record_id = next_id;
            return id;
        }

        pub fn getRecordIdByName(self: *Self, name: []const u8) !RecordId {
            return self.impl.record_map.get(name) orelse return error.NoRecordFound;
        }

        pub fn getRecordById(self: *Self, id: RecordId) Record {
            return self.impl.storage.get(id);
        }

        pub fn getRecordByName(self: *Self, name: []const u8) !Record {
            const id = try self.getRecordIdByName(name);
            return self.getRecordById(id);
        }

        pub fn setRecordByName(self: *Self, name: []const u8, record: SetRecord) !void {
            const id = try self.getRecordIdByName(name);
            try self.setRecordById(id, record);
        }

        pub fn setRecordById(self: *Self, id: RecordId, record: SetRecord) !void {
            var old_record = self.impl.storage.get(id); 
            
            inline for(std.meta.fields(SetRecord)) |field | {
                if(@field(record, field.name)) |val| {
                    @field(old_record, field.name) = val;
                }
            }
            
            self.impl.storage.set(old_record, id);
        }
        
        pub fn print(self: *Self) ![]const u8 {
            const table_writer = &self.impl.table_writer;
            const storage = &self.impl.storage;
            const row_writers = &self.impl.record_writers;

            for(0..storage.len) |i| {
                const record = storage.get(i);
                const row_writer = &row_writers.items[i];
                const writer = &row_writer.writer;
                row_writer.clearRetainingCapacity();
                

                inline for(std.meta.fields(Record)) |field|{
                    try writer.print("{any} " , .{@field(record, field.name)});
                }

                try table_writer.writer.print("{s}\n", .{row_writer.written()});
            }
            return table_writer.written();
        }
    };
}

pub fn getFieldEnum(comptime fields: []const TableFieldEntry) type {
    var names: [fields.len][]const u8 = undefined;
    var values: [fields.len]u8 = undefined;
    
    for(0..fields.len) |i| {
        names[i] = fields[i].id;
        values[i] = @intCast(i);
    }
    
    return @Enum(
        u8,
        .exhaustive, 
        &names, 
        &values,
    );
}

pub fn getRecordType(comptime fields: []const TableFieldEntry, comptime nullable: bool) type {
    var names: [fields.len][]const u8 = undefined;
    var types: [fields.len]type = undefined;
    var attrs: [fields.len]std.builtin.Type.StructField.Attributes = undefined;
    
    for (fields, 0..) |item, i| {
        names[i] = item.id;
        types[i] = blk: {
            if(nullable) break :blk ?item.field_type
            else break :blk item.field_type;
        };
        attrs[i] = blk: {
            if(nullable) break :blk .{.default_value_ptr = &@as(types[i], null) }
            else break :blk .{};
        };
    }
    
    return @Struct(
        .auto,
        null,
        &names,
        &types,
        &attrs,
    );
}

test {
    const Table = ZigTable(&.{
        .{
            .field_type = u8,
            .id = "Age", 
            .fmt_type = .number, 
            .padding = 10,
            .alignment = .center,
        },
        .{
            .field_type = []const u8,
            .id = "Name",
        },
    });

    var table: Table = .init(std.testing.allocator);
    defer table.deinit();

    const id1 = try table.addRecord("Austin", .{.Name = "Austin", .Age = 27});
    const id2 = try table.addRecord(null, .{.Name = "Kayla", .Age = 27});
    try testing.expectEqual(id1, 0);
    try testing.expectEqual(id2, 1);
    try testing.expectEqual(table.impl.storage.len, 2);

    try table.setRecordByName("Austin", .{.Age = 28});
    const reset_record = try table.getRecordByName("Austin");
    try testing.expectEqual(reset_record.Age, 28);

    std.debug.print("{s}\n", .{ try table.print() });
}
