const std = @import("std");

pub const FormatType = enum(u8) {
    // Numeric formats
    number,
    hexadecimal_lc,
    hexadecimal_uc,
    binary_int,
    sci_not,

    // Text and characters
    byte_char,
    string,
    utf8,

    // Names and encodings
    base64,
    tag_name,

    // Addresses and sizes
    byte_count_decimal,
    byte_count_binary,
    ptr_addr,

    custom_format,
    any,
};

pub const perscision_applicable_formats = [_]FormatType{
    .number,
    .hexadecimal_lc,
    .hexadecimal_uc,
    .byte_count_decimal,
    .byte_count_binary,
    .any,
};

pub const FormatModifier = enum(u8) {
    none,
    err_union,
    optional,
    optional_err_union,
    err_union_optional,
};

pub const Alignment = enum(u8) {
    none,
    left,
    center,
    right,
};

const FormatMap = std.StaticStringMap([]const u8).initComptime(.{
    .{"number", "d"},
    .{"hexadecimal_lc", "x"},
    .{"hexadecimal_uc", "X"},
    .{"binary_int", "b"},
    .{"sci_not", "E"},
    .{"byte_char", "c"},
    .{"string", "s"},
    .{"utf8", "u"},
    .{"tag_name", "t"},
    .{"base64", "b64"},
    .{"byte_count_decimal", "B"},
    .{"byte_count_binary", "Bi"},
    .{"ptr_addr", "*"},
    .{"custom_format", "f"},
    .{"any", "any"},
});

pub const FormattingTypes = struct {
    pub const Int = struct {
        pub const Number: FormatType = .number;
        pub const HexadecimalLC: FormatType = .hexadecimal_lc;
        pub const HexadecimalUC: FormatType = .hexadecimal_uc;
        pub const BinaryInt: FormatType = .binary_int;
        pub const SciNot: FormatType = .sci_not;
    };
    
    pub const String = struct {
        pub const String: FormatType = .string;
        pub const ByteChar: FormatType = .byte_char;
        pub const Utf8: FormatType = .utf8;
    };

    pub const Misc = struct {
        pub const TagName: FormatType = .tag_name;
        pub const Base64: FormatType = .base64;
        pub const ByteCountDecimal: FormatType = .byte_count_decimal;
        pub const ByteCountBinary: FormatType = .byte_count_binary;
        pub const PtrAddr: FormatType = .ptr_addr;
        pub const CustomFormat: FormatType = .custom_format;
        pub const Any: FormatType = .any;
    };
};

pub const FormatOptions = struct {
    format_type: FormatType,
    modifier: FormatModifier = .none,
    alignment: Alignment = .none,
    perscision: bool = false,
};

pub fn Format(comptime format_options: FormatOptions) []const u8 {
    const type_name = @tagName(format_options.format_type);
    const formatted = comptime FormatMap.get(type_name) orelse @compileError("FormatType: " ++ type_name ++ " does not exist");

    comptime var output: []const u8 = "{";
    output = output ++ "[v]";

    output = output ++ switch(format_options.modifier) {
        .optional => "?",
        .err_union => "!",
        .optional_err_union => "?!",
        .err_union_optional => "!?",
        .none => "",
    };

    output = output ++ formatted ++ ":";

    output = output ++ switch(format_options.alignment) {
        .left => "<",
        .right => ">",
        .center => "^",
        .none => "",
    };

    if(format_options.alignment != .none) output = output ++ "[w]";
    if(format_options.perscision) output = output ++ ".[p]";
    output = output ++ "}";
    return output;
}

test "every format type produces its expected placeholder" {
    const cases = [_]struct { format_type: FormatType, expected: []const u8 }{
        .{ .format_type = .number, .expected = "{[v]d:}" },
        .{ .format_type = .hexadecimal_lc, .expected = "{[v]x:}" },
        .{ .format_type = .hexadecimal_uc, .expected = "{[v]X:}" },
        .{ .format_type = .binary_int, .expected = "{[v]b:}" },
        .{ .format_type = .sci_not, .expected = "{[v]E:}" },
        .{ .format_type = .byte_char, .expected = "{[v]c:}" },
        .{ .format_type = .string, .expected = "{[v]s:}" },
        .{ .format_type = .utf8, .expected = "{[v]u:}" },
        .{ .format_type = .base64, .expected = "{[v]b64:}" },
        .{ .format_type = .tag_name, .expected = "{[v]t:}" },
        .{ .format_type = .byte_count_decimal, .expected = "{[v]B:}" },
        .{ .format_type = .byte_count_binary, .expected = "{[v]Bi:}" },
        .{ .format_type = .ptr_addr, .expected = "{[v]*:}" },
        .{ .format_type = .custom_format, .expected = "{[v]f:}" },
        .{ .format_type = .any, .expected = "{[v]any:}" },
    };

    try std.testing.expectEqual(std.meta.fields(FormatType).len, cases.len);
    inline for (cases) |case| {
        try std.testing.expectEqualStrings(case.expected, Format(.{ .format_type = case.format_type }));
    }
}

test "modifiers and alignment produce their expected placeholders" {
    const cases = [_]struct { options: FormatOptions, expected: []const u8 }{
        .{ .options = .{ .format_type = .number, .modifier = .none }, .expected = "{[v]d:}" },
        .{ .options = .{ .format_type = .number, .modifier = .err_union }, .expected = "{[v]!d:}" },
        .{ .options = .{ .format_type = .number, .modifier = .optional }, .expected = "{[v]?d:}" },
        .{ .options = .{ .format_type = .number, .modifier = .optional_err_union }, .expected = "{[v]?!d:}" },
        .{ .options = .{ .format_type = .number, .modifier = .err_union_optional }, .expected = "{[v]!?d:}" },
        .{ .options = .{ .format_type = .string, .alignment = .none }, .expected = "{[v]s:}" },
        .{ .options = .{ .format_type = .string, .alignment = .left }, .expected = "{[v]s:<[w]}" },
        .{ .options = .{ .format_type = .string, .alignment = .center }, .expected = "{[v]s:^[w]}" },
        .{ .options = .{ .format_type = .string, .alignment = .right }, .expected = "{[v]s:>[w]}" },
        .{ .options = .{ .format_type = .string, .modifier = .optional_err_union, .alignment = .center }, .expected = "{[v]?!s:^[w]}" },
        .{ .options = .{ .format_type = .number, .perscision = true }, .expected = "{[v]d:.[p]}" },
        .{ .options = .{ .format_type = .number, .alignment = .right, .perscision = true }, .expected = "{[v]d:>[w].[p]}" },
    };

    inline for (cases) |case| {
        try std.testing.expectEqualStrings(case.expected, Format(case.options));
    }
}

test "generated placeholders format values" {
    try std.testing.expectEqualStrings(
        "42",
        std.fmt.comptimePrint(Format(.{ .format_type = .number }), .{ .v = 42 }),
    );
    try std.testing.expectEqualStrings(
        "    3.14",
        std.fmt.comptimePrint(Format(.{ .format_type = .number, .alignment = .right, .perscision = true }), .{
            .v = @as(f64, 3.14159),
            .w = 8,
            .p = 2,
        }),
    );
    try std.testing.expectEqualStrings(
        "  zig",
        std.fmt.comptimePrint(Format(.{ .format_type = .string, .alignment = .right }), .{
            .v = "zig",
            .w = 5,
        }),
    );
}
