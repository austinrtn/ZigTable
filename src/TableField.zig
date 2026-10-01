const std = @import("std");
const TableElementT = @import("TableElement.zig").TableElement;
const Formatting = @import("Formatting.zig");
const FormatType = Formatting.FormatType;
const Alignment = Formatting.Alignment;

pub const TableField = struct {
    name: []const u8,
    fmt_type: FormatType,
    padding: u32 = 0, 
    alignment: Alignment = .none,
};

pub const TableFieldEntry = struct {
    name: []const u8,
    fmt_type: FormatType,
    field_type: type,
    
    padding: u32 = 0, 
    alignment: Alignment = .none,
};

pub fn TableFieldTyped(comptime value_type: type) type {
    return struct {
        const Self = @This();
        const ValueType = value_type;
        const TableElement = TableElementT(ValueType);
        table_field: TableField, 

        pub fn init(table_field: TableField) Self {
            return Self{.table_field = table_field};
        }
    };
}

pub fn isTableField(comptime table_field: type) void {
    if(!@hasDecl(table_field, "TableElement")) @compileError(
        "Invalid type.  Expecting TableElement(T)",
    );
}