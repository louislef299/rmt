const std = @import("std");
const Option = @import("Option.zig").Option;
const OptionError = @import("Option.zig").OptionError;

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
