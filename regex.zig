const re = @cImport({
    @cInclude("regez.h");
});
const REGEX_T_SIZEOF = re.sizeof_regex_t;
const REGEX_T_ALIGNOF = re.alignof_regex_t;

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const slice = try allocator.alignedAlloc(u8, REGEX_T_ALIGNOF, REGEX_T_SIZEOF);
    defer allocator.free(slice);
    const regext: [*]re.regex_t = @ptrCast(slice.ptr);

    if (re.regcomp(regext, "[ab]c", 0) != 0) {
        // TODO: the pattern is invalid
    }
    defer re.regfree(regext); // IMPORTANT!!

    // prints true
    std.debug.print("{any}\n", .{re.isMatch(regext, "ac")});

    // prints false
    std.debug.print("{any}\n", .{re.isMatch(regext, "nope")});
}
