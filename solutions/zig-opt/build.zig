const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    // 1. Define build options for each target
    const opts_a = b.addOptions();
    opts_a.addOption(bool, "enable_feature", true);

    const opts_b = b.addOptions();
    opts_b.addOption(bool, "enable_feature", false);

    // 2. Binary 1: "main" (feature enabled)
    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addOptions("config", opts_a);
    b.installArtifact(exe);

    // 3. Binary 2: "main-old" (feature disabled)
    const exe_old = b.addExecutable(.{
        .name = "main-old",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe_old.root_module.addOptions("config", opts_b);
    b.installArtifact(exe_old);

    // 4. Run step (defaults to running main)
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    // 5. Check step (type checks both executables without emitting binaries)
    const check_step = b.step("check", "Type check the code");
    check_step.dependOn(&exe.step);
    check_step.dependOn(&exe_old.step);
}
