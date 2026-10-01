const std = @import("std");

pub fn TableElement(comptime T: type) type {
    return struct {
        const Self = @This();
        value: T, 
    };
}