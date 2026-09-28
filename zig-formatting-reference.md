# Zig formatting reference

This reference targets **Zig 0.16.0**, the version used by this project. The working examples were compiled and run with that version.

The central rule: **the compiler must know the formatting instructions and argument types; the values being formatted can come from runtime.**

## Format specifiers

| Format | Meaning | Example |
|---|---|---|
| `{}` | Default formatting where supported | Integers, floats, booleans |
| `{d}` | Decimal number | `42`, `3.14` |
| `{x}` / `{X}` | Lowercase/uppercase hexadecimal; also hex-encodes bytes | `255` → `ff` / `FF`; `"hi"` → `6869` |
| `{b}` | Binary integer | `10` → `1010` |
| `{o}` | Octal integer | `10` → `12` |
| `{e}` / `{E}` | Scientific float formatting | `12.5` → `1.25e1`; `E` selects uppercase for special values such as `INF` |
| `{s}` | Text from bytes | `"hello"` → `hello` |
| `{c}` | One byte as a character; integer type at most 8 bits | `65` → `A` |
| `{u}` | Unicode code point encoded as UTF-8; integer type at most 21 bits | `0x1F600` → 😀 |
| `{t}` | Enum/union tag name or error name | `error.Oops` → `Oops` |
| `{b64}` | Base64-encode bytes | `"hi"` → `aGk=` |
| `{B}` | Byte count with decimal units | `1000` → `1kB` |
| `{Bi}` | Byte count with binary units | `1024` → `1KiB` |
| `{*}` | Pointer address | Pass a pointer such as `&value` |
| `{?}` | Optional: payload or `null` | `{?d}` for `?u32`, `{?s}` for `?[]const u8` |
| `{!}` | Error union: payload or error | `{!d}` for `!u32` |
| `{any}` | General structural/default representation | Useful for inspecting structs, slices, optionals |
| `{f}` | Call the value’s custom `format` method | Custom display for your type |

**`{s}`, `{any}`, and `{f}` serve different purposes:** `{s}` displays text, `{any}` displays a value’s structure, and `{f}` uses its custom formatter. `{any}` does not mean the argument’s type is unknown until runtime.

For literal braces, use `{{` and `}}`.

### Duration formatting

The 0.16.0 library comments still mention `{D}`, but the implementation does not support it. Format a duration with:

```zig
std.debug.print("{f}\n", .{
    std.Io.Duration.fromNanoseconds(1_500_000_000),
});
// 1.5s
```

## Placeholder syntax

The full placeholder shape is:

```text
{argument specifier : fill alignment width . precision}
```

The spaces above are explanatory. Most pieces are optional:

```zig
std.debug.print("{d:0>5}\n", .{@as(u32, 42)});       // 00042
std.debug.print("|{s:>8}|\n", .{"Zig"});            // |     Zig|
std.debug.print("{d:.2}\n", .{@as(f64, 3.14159)});   // 3.14
std.debug.print("{1s}: {0d}\n", .{42, "score"});     // score: 42
std.debug.print("{[score]d}\n", .{ .score = 42 });   // 42
```

- `<`, `^`, `>` mean left, center, and right alignment.
- Width is a **minimum** field width, not a truncation limit.
- Text padding counts bytes, not terminal display columns.
- Precision controls numeric formatting; it does not truncate `{s}` strings.
- Options are specifier-dependent.

## Compile time versus runtime

Consider the signature of `std.debug.print`:

```zig
pub fn print(comptime fmt: []const u8, args: anytype) void
```

`comptime fmt` means the compiler must know **the actual bytes of the template**. `args: anytype` means the compiler infers the argument container’s type, including each field’s type. It does **not** require those fields’ values to be compile-time constants.

| Information | Must be known at compile time? |
|---|---|
| Template text, such as `"name={s}, score={d}"` | Yes |
| Specifiers and which arguments they reference | Yes |
| Argument count, field names, and types | Yes |
| Actual numbers and string contents | No |
| Length of a string slice being printed | No |
| Whether an optional is null or an error union contains an error | No |
| Width and precision | Can come from runtime arguments |
| Fill and alignment written into the template | Yes |

### Runtime values

This works with runtime inputs:

```zig
fn report(name: []const u8, score: u32) void {
    std.debug.print("name={s}, score={d}\n", .{ name, score });
}
```

At compile time, Zig checks the placeholders against `[]const u8` and `u32` and produces the formatting code. At runtime, that code reads `name` and `score`, converts the number to text, and writes the output.

### Runtime width and precision

Runtime width and precision are supported through named arguments:

```zig
fn show(value: f64, width: usize, precision: usize) void {
    std.debug.print("|{[v]d:>[w].[p]}|\n", .{
        .v = value,
        .w = width,
        .p = precision,
    });
}

// show(3.14159, 8, 2) prints:
// |    3.14|
```

The compiler knows to fetch width from `w` and precision from `p`. Their numeric values can remain unknown until the function runs.

### Runtime templates

A runtime template does not work with `std.debug.print`:

```zig
fn bad(template: []const u8, value: u32) void {
    std.debug.print(template, .{value}); // Compile error
}
```

When runtime logic chooses between formats, put the calls inside the branches:

```zig
fn showNumber(value: u32, hex: bool) void {
    if (hex) {
        std.debug.print("{x}\n", .{value});
    } else {
        std.debug.print("{d}\n", .{value});
    }
}
```

Each call has a compile-time-known template; runtime control flow selects which call executes.

If you just want to print runtime text, pass it as data:

```zig
std.debug.print("{s}", .{runtime_text});
```

Braces inside `runtime_text` are printed literally.

## Common sources of confusion

- **`const` does not mean `comptime`.** `const value = readSomething();` prevents reassignment, but the value can still come from runtime.
- **A compile-time template does not make the output compile-time.** `std.fmt.bufPrint` and `std.fmt.allocPrint` accept runtime values. `std.fmt.comptimePrint` builds the result during compilation, so everything needed to produce that result must be compile-time-known.

## References

- [Zig 0.16.0 standard library: Writer.print](https://ziglang.org/documentation/0.16.0/std/#std.Io.Writer.print)
- [Zig 0.16.0 language reference: Compile-Time Parameters](https://ziglang.org/documentation/0.16.0/#Compile-Time-Parameters)
- Implementation checked locally: Zig 0.16.0 `lib/std/Io/Writer.zig`, `lib/std/fmt.zig`, and `lib/std/Io.zig`.
