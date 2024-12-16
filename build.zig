const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //================ADD EXE=======================
    const exe = b.addExecutable(.{
        .name = "accountr",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_test = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    //================ADD DVUI======================
    //const dvui = b.dependency("dvui", .{
    //    .target = target,
    //    .optimize = optimize,
    //    .link_backend = true,
    //});
    //exe.root_module.addImport("dvui", dvui.module("dvui_raylib"));
    //exe_test.root_module.addImport("dvui", dvui.module("dvui_raylib"));

    b.installArtifact(exe);

    //===============RUN STEPS======================
    const run_step = b.step("run", "Run the app");
    const run_exe = b.addRunArtifact(exe);
    run_step.dependOn(&run_exe.step);

    const run_exe_unit_tests = b.addRunArtifact(exe_test);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
