const std = @import("std");
const SmartSoA = @import("SmartSoA").SmartSoA;
const TableFieldMod = @import("TableField.zig");

const ArrayList = std.ArrayList;
const Writer = std.Io.Writer.Allocating;
const TableField = TableFieldMod.TableField;
const TableFieldEntry = TableFieldMod.TableFieldEntry;
const isTableField = TableFieldMod.isTableField;

pub fn ZigTable(comptime fields: []const TableFieldEntry) type {
    const FieldEnum = getFieldEnum(fields);
    _ = FieldEnum;
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        storage: Storage(fields),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator, .storage = .init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.storage.deinit();
        }
    };
}

pub fn getFieldEnum(comptime fields: []const TableFieldEntry) type {
    var names: [fields.len][]const u8 = undefined;
    var values: [fields.len]u8 = undefined;
    
    for(0..fields.len) |i| {
        names[i] = fields[i].name;
        values[i] = @intCast(i);
    }
    
    return @Enum(
        u8,
        .exhaustive, 
        &names, 
        &values,
    );
}

pub fn Storage(comptime fields: []const TableFieldEntry) type {
    const FieldEnum = getFieldEnum(fields);
    const FieldTags = std.meta.tags(FieldEnum);
    
    return struct {
        const Self = @This();
        inner: getStorage(fields) = undefined,
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator) Self {
            var self: Self = .{.allocator = allocator};
            inline for(FieldTags) |field| {
                @field(self.inner, @tagName(field)) = .empty;
            }
            return self;
        }

        fn deinit(self: *Self) void {
            inline for(FieldTags) |field| {
                @field(self.inner, @tagName(field)).deinit(self.allocator);
            }
        }
    };
}

pub fn getStorage(comptime fields: []const TableFieldEntry) type {
    var names: [fields.len][]const u8 = undefined;
    var types: [fields.len]type = undefined;
    var attrs: [fields.len]std.builtin.Type.StructField.Attributes = undefined;
    
    for (fields, 0..) |field, i| {
        names[i] = field.name;
        types[i] = ArrayList(field.field_type);
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

pub fn getFieldTypes(comptime fields: []type) []type {
    var types: [fields.len]type = undefined;

    for(0..fields.len) |i| {
        types[i] = fields[i].ValueType;
    }
    
    return types;
}


test {
    var table: ZigTable(&.{
        .{
            .field_type = u8,
            .name = "Age", 
            .fmt_type = .number, 
            .padding = 10,
            .alignment = .center,
        },
    }) = .init(std.testing.allocator);
    defer table.deinit();
}