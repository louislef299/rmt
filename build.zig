const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
};

const version: std.SemanticVersion = .{
    .major = 0,
    .minor = 0,
    .patch = 2,
};

fn addExeOptions(o: *std.Build.Step.Options, comptime q: std.Target.Query) void {
    o.addOption([]const u8, "cpu_arch", @tagName(q.cpu_arch orelse unreachable));
    o.addOption([]const u8, "os", @tagName(q.os_tag orelse unreachable));

    if (q.abi) |a| {
        o.addOption([]const u8, "abi", std.fmt.comptimePrint("-{s}", .{@tagName(a)}));
    } else {
        o.addOption([]const u8, "abi", "");
    }
    o.addOption([]const u8, "version", std.fmt.comptimePrint("{d}.{d}.{d}", .{ version.major, version.minor, version.patch }));
}

fn addRunSteps(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run rmt");
    run_step.dependOn(&run_cmd.step);
}

fn addTestSteps(b: *std.Build, t: std.Build.ResolvedTarget, o: std.builtin.OptimizeMode) void {
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = t,
        .optimize = o,
    });
    linkSLRE(b, exe_unit_tests);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn linkSLRE(b: *std.Build, exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(b.path("slre"));
    exe.addCSourceFile(.{ .file = b.path("slre/slre.c") });
    exe.linkLibC();
}

fn buildTarget(b: *std.Build, comptime q: std.Target.Query, t: std.Build.ResolvedTarget, o: std.builtin.OptimizeMode, exeName: []const u8) *std.Build.Step.Compile {
    const options = b.addOptions();
    const exe = b.addExecutable(.{
        .name = exeName,
        .root_source_file = b.path("src/main.zig"),
        .target = t,
        .optimize = o,
    });
    linkSLRE(b, exe);
    addExeOptions(options, q);

    exe.root_module.addOptions("build_config", options);
    b.installArtifact(exe);
    return exe;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (b.option(bool, "release-build", "Build executables for release target architectures") orelse false) {
        inline for (targets) |t| {
            const exeName = std.fmt.comptimePrint("rmt-{s}-{s}{s}", .{
                @tagName(t.cpu_arch orelse unreachable),
                @tagName(t.os_tag orelse unreachable),
                if (t.abi) |a| "-" ++ @tagName(a) else "",
            });
            _ = buildTarget(b, t, target, .ReleaseSafe, exeName);
        }
    } else {
        const exe = buildTarget(b, .{}, target, optimize, "rmt");
        addRunSteps(b, exe);
        addTestSteps(b, target, optimize);
    }
}
