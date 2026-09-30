const std = @import("std");
const Formatting = @import("Formatting.zig");
const FormatType = Formatting.FormatType;
const Alignment = Formatting.Alignment;

pub fn TableField(comptime T: type) type {
    struct {
        const Self = @This(); 
        pub const ValueType = T;
        
        name: []const u8,
        impl: struct {
            val: T,
            fmt_type: FormatType,
        
            padding: u32 = 0, 
            alignment: Alignment = .none,
        },
        
        pub fn setVal(self: *Self, value: ValueType) void {
            self.impl.val = value;
        }

        pub fn setPadding(self: *Self, value: u32) void {
            self.impl.padding = value;
        }

        pub fn setAlignment(self: *Self, value: Alignment) void {
            self.impl.alignment = value;
        }
    };
}