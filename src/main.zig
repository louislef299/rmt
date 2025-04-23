const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    var it = cwd.iterate();
    while (try it.next()) |entry| {
        try stdout.print("{s}\n", .{entry.name});
    }

    std.debug.print("we are now going to try walking through the dir...\n", .{});
    const allocator = std.heap.page_allocator;

    var walker = try cwd.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        try stdout.print("{s}\n", .{entry.path});
    }
}
