const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
};

pub fn build(b: *std.Build) void {
    const version: std.SemanticVersion = .{
        .major = 0,
        .minor = 0,
        .patch = 2,
    };
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (b.option(bool, "release-build", "Build executables for release target architectures") orelse false) {
        //=> Release Build Flow <=//
        inline for (targets) |t| {
            const options = b.addOptions();
            options.addOption([]const u8, "version", std.fmt.comptimePrint("{d}.{d}.{d}", .{ version.major, version.minor, version.patch }));

            const arch = @tagName(t.cpu_arch orelse unreachable);
            const os = @tagName(t.os_tag orelse unreachable);
            const abi = if (t.abi) |a| "-" ++ @tagName(a) else "";
            options.addOption([]const u8, "cpu_arch", arch);
            options.addOption([]const u8, "os", os);
            options.addOption([]const u8, "abi", abi);

            const exe = b.addExecutable(.{
                .name = std.fmt.comptimePrint("rmt-{s}-{s}{s}", .{ arch, os, abi }),
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(t),
                .optimize = .ReleaseSafe,
            });
            exe.addIncludePath(b.path("slre"));
            exe.addCSourceFile(.{ .file = b.path("slre/slre.c") });
            exe.linkLibC();

            exe.root_module.addOptions("build_config", options);
            b.installArtifact(exe);
        }
    } else {
        const options = b.addOptions();
        options.addOption([]const u8, "version", std.fmt.comptimePrint("{d}.{d}.{d}", .{ version.major, version.minor, version.patch }));
        options.addOption([]const u8, "cpu_arch", "dev");
        options.addOption([]const u8, "os", "dev");
        options.addOption([]const u8, "abi", "");

        //=> Normal Build Flow <=//
        const exe = b.addExecutable(.{
            .name = "rmt",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .version = version,
        });

        exe.addIncludePath(b.path("slre"));
        exe.addCSourceFile(.{ .file = b.path("slre/slre.c") });
        exe.linkLibC();

        exe.root_module.addOptions("build_config", options);
        b.installArtifact(exe);

        //=> Run Steps <=//
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run", "Run rmt");
        run_step.dependOn(&run_cmd.step);

        //=> Test Steps <=//
        const exe_unit_tests = b.addTest(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe_unit_tests.addIncludePath(b.path("slre"));
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }
}
