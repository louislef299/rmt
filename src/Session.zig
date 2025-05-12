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
            del = try interactiveDelete(f);
        }

        if (del) {
            std.debug.print("deleting file {s}\n", .{file});
        } else {
            std.debug.print("skipping deletion of {s}\n", .{file});
        }
    }
};

fn interactiveDelete(f: std.fs.File) !bool {
    const r = f.reader();

    var buf: [10]u8 = undefined;
    _ = try r.readUntilDelimiterOrEof(&buf, '\n');

    return (std.mem.eql(u8, &buf, "yes") or std.mem.eql(u8, &buf, "y"));
}
