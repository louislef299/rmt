const std = @import("std");
const Allocator = std.mem.Allocator;
const re = @cImport(@cInclude("regez.h"));

const REGEX_T_SIZEOF = re.sizeof_regex_t;
const REGEX_T_ALIGNOF = re.alignof_regex_t;
const EMACS_TILDE = ".*~$";

pub const OptionError = error{
    UnknownInput,
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
            return OptionError.UnknownInput;
        }
    }

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cwd.close();

    const stdin = std.io.getStdIn();

    const slice = try allocator.alignedAlloc(u8, REGEX_T_ALIGNOF, REGEX_T_SIZEOF);
    defer allocator.free(slice);

    const regext: [*]re.regex_t = @ptrCast(slice.ptr);
    if (re.regcomp(regext, EMACS_TILDE, 0) != 0) {
        return std.debug.panic("failed to allocate regex memory\n", .{});
    }

    // if recursive, walk the filesystem from cwd
    if (recursive) {
        var walker = try cwd.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            try delete(stdin, cwd, entry.path, interactive, regext);
        }
    } else {
        var it = cwd.iterate();
        while (try it.next()) |entry| {
            try delete(stdin, cwd, entry.name, interactive, regext);
        }
    }
}

fn printHelp() !void {
    return std.io.getStdOut().writer().writeAll(usage);
}

pub fn delete(f: std.fs.File, cwd: std.fs.Dir, file: []const u8, i: bool, regext: [*]re.regex_t) !void {
    const c_file: [*:0]const u8 = @ptrCast(file);
    if (re.isMatch(regext, c_file)) {
        var del: bool = true;
        if (i) {
            del = try interactiveDelete(f, file);
        }
        if (del) {
            std.debug.print("deleting file {s}\n", .{file});
            try cwd.deleteFile(file);
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
