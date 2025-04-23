const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    var it = cwd.iterate();
    while (try it.next()) |entry| {
        try stdout.print("{s}\n", .{entry.name});
    }
}
