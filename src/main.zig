const std = @import("std");
const config = @import("build_config");
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
    \\  --version           Print version & build information
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
        } else if (std.mem.eql(u8, arg, "--version")) {
            return printVersion();
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
            defer allocator.free(cSlice);

            @memcpy(cSlice[0..entry.name.len], entry.name);
            cSlice[entry.name.len] = 0;

            try delete(stdin, cwd, cSlice[0..entry.name.len :0], interactive);
        }
    }
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

fn printHelp() !void {
    return std.io.getStdOut().writer().writeAll(usage);
}

fn printVersion() !void {
    return std.debug.print("rmt-v{s}-{s}-{s}{s}\n", .{ config.version, config.cpu_arch, config.os, config.abi });
}

test "delete function with emacs backup file" {
    const testing = std.testing;

    // Create a temporary directory for testing
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    // Create a test file with tilde suffix
    const test_file = "test_file.txt~";
    const file = try tmp_dir.dir.createFile(test_file, .{});
    file.close();

    // Test pattern matching logic for emacs backup files
    const match_result = c.slre_match(
        EMACS_TILDE,
        test_file.ptr,
        test_file.len,
        null,
        0,
        0,
    );

    try testing.expect(match_result >= 0);
}

test "delete function with non-emacs file" {
    const testing = std.testing;

    const test_file = "normal_file.txt";

    // Test pattern matching - should not match
    const match_result = c.slre_match(
        EMACS_TILDE,
        test_file.ptr,
        test_file.len,
        null,
        0,
        0,
    );

    try testing.expect(match_result < 0);
}

test "delete function pattern matching various cases" {
    const testing = std.testing;

    const test_cases = [_]struct {
        filename: []const u8,
        should_match: bool,
    }{
        .{ .filename = "file.txt~", .should_match = true },
        .{ .filename = "~file.txt", .should_match = false },
        .{ .filename = "file~.txt", .should_match = false },
        .{ .filename = "file.txt", .should_match = false },
        .{ .filename = ".emacs~", .should_match = true },
        .{ .filename = "very_long_filename_with_spaces and stuff.org~", .should_match = true },
        .{ .filename = "a~", .should_match = true },
        .{ .filename = "~", .should_match = true },
        .{ .filename = "", .should_match = false },
    };

    for (test_cases) |case| {
        // Create null-terminated string for C function
        var arena = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const null_terminated = try allocator.dupeZ(u8, case.filename);

        const match_result = c.slre_match(
            EMACS_TILDE,
            null_terminated.ptr,
            @intCast(null_terminated.len),
            null,
            0,
            0,
        );

        if (case.should_match) {
            try testing.expect(match_result >= 0);
        } else {
            try testing.expect(match_result < 0);
        }
    }
}

test "interactiveDelete response logic" {
    const testing = std.testing;

    // Test the string comparison logic used in interactiveDelete
    const test_responses = [_][]const u8{ "yes", "y", "no", "n", "maybe", "" };
    const expected_results = [_]bool{ true, true, false, false, false, false };

    for (test_responses, expected_results) |response, expected| {
        const trimmed = std.mem.trim(u8, response, "\r");
        const result = (std.mem.eql(u8, trimmed, "yes") or std.mem.eql(u8, trimmed, "y"));
        try testing.expect(result == expected);
    }
}

test "interactiveDelete response parsing" {
    const testing = std.testing;

    // Test Windows-style line ending handling
    const windows_response = "yes\r\n";
    const trimmed = std.mem.trim(u8, windows_response, "\r\n");
    try testing.expectEqualStrings("yes", trimmed);

    // Test Unix-style line ending
    const unix_response = "y\n";
    const trimmed_unix = std.mem.trim(u8, unix_response, "\r\n");
    try testing.expectEqualStrings("y", trimmed_unix);
}
