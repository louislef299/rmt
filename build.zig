const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (b.option(bool, "release-build", "Build executables for release target architectures") orelse false) {
        for (targets) |t| {
            const exe = b.addExecutable(.{
                .name = "rmt",
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(t),
                .optimize = .ReleaseSafe,
            });
            exe.addIncludePath(b.path("lib/regez"));
            exe.addCSourceFile(.{ .file = b.path("lib/regez/regez.c") });
            exe.linkLibC();
            b.installArtifact(exe);
        }
    } else {
        //=> Normal Build Flow <=//

        const exe = b.addExecutable(.{
            .name = "rmt",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.addIncludePath(b.path("lib/regez"));
        exe.linkLibC();
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
        exe_unit_tests.addIncludePath(b.path("lib/regez"));
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }
}
