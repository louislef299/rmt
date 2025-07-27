const std = @import("std");
const c = @cImport({
    @cInclude("slre.h");
});

const EMACS_TILDE = ".*~$";

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

    var recursive: bool = false;
    var interactive: bool = false;
    // didn't use switch here as I don't think zig supports that yet
    // https://www.openmymind.net/Switching-On-Strings-In-Zig/?
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--recursive") or std.mem.eql(u8, arg, "-r")) {
            recursive = true;
        } else if (std.mem.eql(u8, arg, "--interactive") or std.mem.eql(u8, arg, "-i")) {
            interactive = true;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            return printHelp();
        } else {
            std.debug.print("Unknown option: {s}\n", .{arg});
            return printHelp();
        }
    }

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    const stdin = std.io.getStdIn();

    // if recursive, walk the filesystem from cwd
    if (recursive) {
        var walker = try cwd.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            try delete(stdin, cwd, entry.path, interactive);
        }
    } else {
        var it = cwd.iterate();
        while (try it.next()) |entry| {
            // Dir.Entry returns a []const u8 and isn't null-terminated. have to
            // handle that case here...
            var cSlice = try allocator.alloc(u8, entry.name.len + 1);
            @memcpy(cSlice[0..cSlice.len], entry.name);
            cSlice[entry.name.len] = 0;

            try delete(stdin, cwd, cSlice[0.. :0], interactive);
        }
    }
}

fn printHelp() !void {
    return std.io.getStdOut().writer().writeAll(usage);
}

pub fn delete(f: std.fs.File, cwd: std.fs.Dir, file: [:0]const u8, i: bool) !void {
    const match = c.slre_match(
        EMACS_TILDE,
        file.ptr,
        @intCast(file.len),
        null, // no capture groups
        0,
        0,
    );

    if (match >= 0) {
        var del: bool = true;
        if (i) {
            del = try interactiveDelete(f, file);
        }
        if (del) {
            std.debug.print("deleting file {s}\n", .{file});
            cwd.deleteFile(file) catch |err| {
                std.debug.print("skipping {s} due to error: {}\n", .{ file, err });
                return;
            };
            return;
        }
    }
}

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
