const std = @import("std");

pub const OptionError = error{
    UnknownInput,
    HelpMsg,
};

// Represents the File and General Options available.
pub const Session = struct {
    recursive: bool = false,
    interactive: bool = false,

    // Parses the provided arguments and returns an Option type based on the
    // provided arguments. Attempts to avoid any printing done by the Option
    // type in favor of the user deciding how to act on the returned errors.
    pub fn init(args: []const []const u8) !Session {
        var s = Session{};

        // didn't use switch here as I don't think zig supports that yet
        // https://www.openmymind.net/Switching-On-Strings-In-Zig/?
        for (args) |arg| {
            if (std.mem.eql(u8, arg, "--recursive") or std.mem.eql(u8, arg, "-r")) {
                s.recursive = true;
            } else if (std.mem.eql(u8, arg, "--interactive") or std.mem.eql(u8, arg, "-i")) {
                s.interactive = true;
            } else if (std.mem.eql(u8, arg, "--help")) {
                return OptionError.HelpMsg;
            } else {
                return OptionError.UnknownInput;
            }
        }
        return s;
    }

    pub fn delete(self: Session, f: std.fs.File, file: []const u8) !void {
        var del = true;
        if (self.interactive) {
            del = try interactiveDelete(f, file);
        }

        if (del) {
            std.debug.print("deleting file {s}\n", .{file});
        } else {
            std.debug.print("skipping deletion of {s}\n", .{file});
        }
    }
};

fn interactiveDelete(f: std.fs.File, name: []const u8) !bool {
    const r = f.reader();

    try std.io.getStdOut().writer().print("delete file {s}? ", .{name});

    const bare_line = try r.readUntilDelimiterAlloc(
        std.heap.page_allocator,
        '\n',
        512,
    );
    defer std.heap.page_allocator.free(bare_line);

    // Because of legacy reasons newlines in many places in Windows are represented
    // by the two-character sequence \r\n, which means that we must strip \r from
    // the line that we've read. Without this our program will behave incorrectly
    // on Windows.
    const line = std.mem.trim(u8, bare_line, "\r");

    return (std.mem.eql(u8, line, "yes") or std.mem.eql(u8, line, "y"));
}
