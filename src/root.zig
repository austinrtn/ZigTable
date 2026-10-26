const std = @import("std");
pub const ZigTable = @import("ZigTable.zig").ZigTable;
pub const Formatting = @import("Formatting.zig");
pub const TableFieldEntry = @import("TableField.zig").TableFieldEntry;

test "root" {
    _ = @import("ZigTable.zig");
}
