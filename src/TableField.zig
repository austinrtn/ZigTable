const std = @import("std");
const TableElementT = @import("TableElement.zig").TableElement;
const Formatting = @import("Formatting.zig");
const FormatType = Formatting.FormatType;
const Alignment = Formatting.Alignment;

pub const TableField = struct {
    id: []const u8,
    display_name: []const u8, 
    fmt_type: FormatType = .any,
    padding: u32 = 0, 
    alignment: Alignment = .none,
    auto_align:bool = false,
};

pub const TableFieldEntry = struct {
    id: []const u8,
    display_name: []const u8 = "",
    field_type: type,
    
    fmt_type: FormatType = .any,
    padding: u32 = 0, 
    alignment: Alignment = .none,
    auto_align:bool = false,

    pub fn getTableField(self: @This()) TableField {
        return .{
            .fmt_type = self.fmt_type,
            .id = self.id,
            .display_name = self.display_name,
            .alignment = self.alignment,
            .padding = self.padding,
            .auto_align = self.auto_align,
        };
    }
};