const std = @import("std");
const SmartSoA = @import("SmartSoA").SmartSoA;
const TableFieldMod = @import("TableField.zig");

const ArrayList = std.ArrayList;
const Writer = std.Io.Writer.Allocating;
const TableField = TableFieldMod.TableField;
const TableFieldTyped = TableFieldMod.TableFieldTyped;
const isTableField = TableFieldMod.isTableField;

pub fn ZigTable(comptime fields: []type) type {
    const FieldTypes = getFieldTypes(fields);
    _ = FieldTypes;
    
    return struct {
        pub const FieldEnum = getFieldEnum(fields);
    
    };
}

pub fn getFieldTypes(comptime fields: []type) []type {
    var types: [fields.len]type = undefined;

    for(0..fields.len) |i| {
        types[i] = fields[i].ValueType;
    }
    
    return types;
}

pub fn getFieldEnum(comptime fields: []type) type {
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

test {
    const fields = [_]type{
        TableFieldTyped(u32).init(.{ .name = "age", .fmt_type = .number, }),
        TableFieldTyped([]const u8).init(.{ .name = "address", .fmt_type = .string, }),
    };

    const table = ZigTable(&fields){};
    _ = table;

}