const std = @import("std");
const Session = @import("Session.zig").Session;
const OptionError = @import("Session.zig").OptionError;

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

    // parse command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // generate Options provided by user and skip args[0] as that is the actual
    // rmt argument
    const sess = Session.init(allocator, args[1..]) catch |err| switch (err) {
        OptionError.HelpMsg => {
            try printHelp();
            return;
        },
        else => {
            std.debug.print("issue reading from args: {s}\n", .{args});
            return err;
        },
    };
    defer {
        sess.deinit();
    }

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    const stdin = std.io.getStdIn();

    // if recursive, walk the filesystem from cwd
    if (sess.recursive) {
        var walker = try cwd.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            try sess.delete(stdin, entry.path);
        }
    } else {
        var it = cwd.iterate();
        while (try it.next()) |entry| {
            try sess.delete(stdin, entry.name);
        }
    }
}

fn printHelp() !void {
    return std.io.getStdErr().writer().writeAll(usage);
}
