const std = @import("std");
const TableElementT = @import("TableElement.zig").TableElement;
const Formatting = @import("Formatting.zig");
const FormatType = Formatting.FormatType;
const Alignment = Formatting.Alignment;

pub const TableField = struct {
    display_name: []const u8, 
    fmt_type: FormatType = .any,
    padding: u32 = 0, 
    alignment: Alignment = .none,
};

pub const TableFieldEntry = struct {
    id: []const u8,
    field_type: type,
    
    fmt_type: FormatType = .any,
    padding: u32 = 0, 
    alignment: Alignment = .none,
};