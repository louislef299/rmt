const std = @import("std");
const io = std.io;
const mem = std.mem;

const usage =
    \\Usage: rmt [options]
    \\
    \\General Options:
    \\
    \\  -h, --help       Print command-specific usage
    \\  -i, --interactive   interactive output
    \\  -r, --recursive  Walk filepath starting at current directory
    \\
;

// Create an Option type, figure out what options are set based on flags, return
// Options type, and then run the rmt filesystem logic

// Represents the General Options available.
pub const Option = struct {
    recursive: bool,
    interactive: bool,

    // Parses the provided arguments and returns an Option type based on the
    // provided arguments.
    fn init(args: []const []const u8) !Option {
        var r = false;
        var inter = false;

        for (args) |arg| {
            if (mem.eql(u8, arg, "--recursive") || mem.eql(u8, arg, "-r")) {
                r = true;
            } else if (mem.eql(u8, arg, "--interactive") || mem.eql(u8, arg, "-i")) {
                inter = true;
            } else if (mem.eql(u8, arg, "--help")) {
                return io.getStdOut().writeAll(usage);
            } else {
                std.debug.print("unknown option {s}\n", .{arg});
                return io.getStdOut().writeAll(usage);
            }
        }

        return .{
            .recursive = r,
            .interactive = inter,
        };
    }
};

// when you get to parsing args, just take a look at the process lib:
// https://ziglang.org/documentation/0.14.0/std/#std.process
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Parse command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const option = try Option.init(args);

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    if (option.recursive) {
        std.debug.print("we are now going to try walking through the dir...\n", .{});
        var walker = try cwd.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            try std.debug.print("{s}\n", .{entry.path});
        }
    } else {
        std.debug.print("just looking in the current directory...\n", .{});
        var it = cwd.iterate();
        while (try it.next()) |entry| {
            try std.debug.print("{s}\n", .{entry.name});
        }
    }
}
