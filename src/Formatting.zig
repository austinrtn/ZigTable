const std = @import("std");

pub const FormatType = enum(u8) {
    // Numeric formats
    Number,
    HexadecimalLC,
    HexadecimalUC,
    BinaryInt,
    SciNot,

    // Text and characters
    ByteChar,
    String,
    Utf8,

    // Names and encodings
    Base64,
    TagName,

    // Addresses and sizes
    ByteCountDecimal,
    ByteCountBinary,
    PtrAddr,

    CustomFormat,
    Any,
};

const FormatMap = std.StaticStringMap([]const u8).initComptime(.{
    .{"Number", "d"},
    .{"HexadecimalLC", "x"},
    .{"HexadecimalUC", "X"},
    .{"BinaryInt", "b"},
    .{"SciNot", "E"},
    .{"ByteChar", "c"},
    .{"String", "s"},
    .{"Utf8", "u"},
    .{"TagName", "t"},
    .{"Base64", "b64"},
    .{"ByteCountDecimal", "B"},
    .{"ByteCountBinary", "Bi"},
    .{"PtrAddr", "*"},
    .{"CustomFormat", "f"},
    .{"Any", "any"},
});

pub const FormattingTypes = struct {
    pub const Int = struct {
        pub const Number: FormatType = .Number;
        pub const HexadecimalLC: FormatType = .HexadecimalLC;
        pub const HexadecimalUC: FormatType = .HexadecimalUC;
        pub const BinaryInt: FormatType = .BinaryInt;
        pub const SciNot: FormatType = .SciNot;
    };
    
    pub const String = struct {
        pub const String: FormatType = .String;
        pub const ByteChar: FormatType = .ByteChar;
        pub const Utf8: FormatType = .Utf8;
    };

    pub const Misc = struct {
        pub const TagName: FormatType = .TagName;
        pub const Base64: FormatType = .Base64;
        pub const ByteCountDecimal: FormatType = .ByteCountDecimal;
        pub const ByteCountBinary: FormatType = .ByteCountBinary;
        pub const PtrAddr: FormatType = .PtrAddr;
        pub const CustomFormat: FormatType = .CustomFormat;
        pub const Any: FormatType = .Any;
    };
};

pub const FormatOptions = struct {
    comptime format_type: FormatType = .Any, 
};

pub fn Format(comptime format_options: FormatOptions) []const u8 {
    const type_name = @tagName(format_type);
    const formatted = FormatMap.get(type_name) orelse @compileError("FormatType: " ++ type_name ++ " does not exist");
}