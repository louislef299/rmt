const std = @import("std");

// when you get to parsing args, just take a look at the process lib:
// https://ziglang.org/documentation/0.14.0/std/#std.process
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Parse command-line arguments
    var args = std.process.args();

    // const recursive = std.cli.flag("--recursive", "List files
    // recursively.");
    const recursive = false;
    var count: usize = 0;
    while (args.next()) |arg| {
        if (count != 0) {
            std.debug.print("arg {d}: {s}\n", .{ count, arg });
        }
        count += 1;
    }

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    if (recursive) {
        std.debug.print("we are now going to try walking through the dir...\n", .{});
        var walker = try cwd.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            try stdout.print("{s}\n", .{entry.path});
        }
    } else {
        std.debug.print("just looking in the current directory...\n", .{});
        var it = cwd.iterate();
        while (try it.next()) |entry| {
            try stdout.print("{s}\n", .{entry.name});
        }
    }
}
