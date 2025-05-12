const std = @import("std");

const OptionError = error{
    UnknownInput,
    HelpMsg,
};

const usage =
    \\Usage: rmt [options]
    \\
    \\General Options:
    \\
    \\  -h, --help          Print command-specific usage
    \\  -i, --interactive   Interactive output
    \\  -r, --recursive     Walk filepath starting at current directory
    \\
;

// Create an Option type, figure out what options are set based on flags, return
// Options type, and then run the rmt filesystem logic

// when you get to parsing args, just take a look at the process lib:
// https://ziglang.org/documentation/0.14.0/std/#std.process
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Parse command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Generate Options provided by user
    const o = Option.init(args[1..]) catch |err| switch (err) {
        OptionError.HelpMsg => {
            try printHelp();
            return;
        },
        else => {
            std.debug.print("issue reading from args: {s}\n", .{args});
            return err;
        },
    };

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    // if recursive, walk the filesystem from cwd
    if (o.recursive) {
        var walker = try cwd.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            std.debug.print("{s}\n", .{entry.path});
        }
    } else {
        var it = cwd.iterate();
        while (try it.next()) |entry| {
            std.debug.print("{s}\n", .{entry.name});
        }
    }
}

fn printHelp() !void {
    return std.io.getStdErr().writer().writeAll(usage);
}

// Represents the General Options available.
pub const Option = struct {
    recursive: bool,
    interactive: bool,

    // Parses the provided arguments and returns an Option type based on the
    // provided arguments. Attempts to avoid any printing done by the Option
    // type in favor of the user deciding how to act on the returned errors.
    fn init(args: []const []const u8) !Option {
        var r = false;
        var inter = false;

        // didn't use switch here as I don't think zig supports that yet
        for (args) |arg| {
            if (std.mem.eql(u8, arg, "--recursive") or std.mem.eql(u8, arg, "-r")) {
                r = true;
            } else if (std.mem.eql(u8, arg, "--interactive") or std.mem.eql(u8, arg, "-i")) {
                inter = true;
            } else if (std.mem.eql(u8, arg, "--help")) {
                return OptionError.HelpMsg;
            } else {
                return OptionError.UnknownInput;
            }
        }

        return .{
            .recursive = r,
            .interactive = inter,
        };
    }
};
