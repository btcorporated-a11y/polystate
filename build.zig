const std = @import("std");
pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .macos }, 
    };
    const archive_step = b.step("archive", "Package all builds into tar.gz archives");
    const test_step = b.step("test", "Run all tests");
    for (targets) |t| {
        buildForTarget(b, t, optimize, archive_step, test_step);
    }
}
fn buildForTarget(
    b: *std.Build,
    target_query: std.Target.Query,
    optimize: std.builtin.OptimizeMode,
    archive_step: *std.Build.Step,
    test_step: *std.Build.Step,
) void {
    const target_name = target_query.zigTriple(b.allocator) catch "unknown-target";
    const resolved_target = b.resolveTargetQuery(target_query);
    const weon_sdk_module = b.addModule("weon-sdk", .{
        .root_source_file = b.path("src/root.zig"),
        .target = resolved_target,
        .optimize = optimize,
    });
    weon_sdk_module.addIncludePath(b.path("include"));
    const static_lib = createLibrary(b, weon_sdk_module, .static);
    const shared_lib = createLibrary(b, weon_sdk_module, .dynamic);
    const install_deps = installTargetArtifacts(b, target_name, static_lib, shared_lib);
    setupArchive(b, target_name, archive_step, install_deps);
    setupTests(b, resolved_target, optimize, test_step, weon_sdk_module, static_lib);
}
fn createLibrary(b: *std.Build, module: *std.Build.Module, linkage: std.builtin.LinkMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "weon-sdk",
        .root_module = module,
        .linkage = linkage,
    });
    lib.root_module.link_libc = true;
    return lib;
}
fn installTargetArtifacts(
    b: *std.Build,
    target_name: []const u8,
    static_lib: *std.Build.Step.Compile,
    shared_lib: *std.Build.Step.Compile,
) [4]*std.Build.Step {
    const lib_out_dir = b.fmt("{s}/lib", .{target_name});
    const install_static = b.addInstallArtifact(static_lib, .{
        .dest_dir = .{ .override = .{ .custom = lib_out_dir } },
    });
    const install_shared = b.addInstallArtifact(shared_lib, .{
        .dest_dir = .{ .override = .{ .custom = lib_out_dir } },
    });
    const install_include = b.addInstallDirectory(.{
        .source_dir = b.path("include"),
        .install_dir = .prefix,
        .install_subdir = b.fmt("{s}/include", .{target_name}),
    });
    const install_src = b.addInstallDirectory(.{
        .source_dir = b.path("src"),
        .install_dir = .prefix,
        .install_subdir = b.fmt("{s}/src", .{target_name}),
    });
    b.getInstallStep().dependOn(&install_static.step);
    b.getInstallStep().dependOn(&install_shared.step);
    b.getInstallStep().dependOn(&install_include.step);
    b.getInstallStep().dependOn(&install_src.step);
    return .{ &install_static.step, &install_shared.step, &install_include.step, &install_src.step };
}
fn setupArchive(
    b: *std.Build,
    target_name: []const u8,
    archive_step: *std.Build.Step,
    dependencies: [4]*std.Build.Step,
) void {
    const tar_cmd = b.addSystemCommand(&.{ "tar", "-czf" });
    std.fs.cwd().makePath("bin") catch {};
    const archive_name = b.fmt("bin/weon-sdk-{s}.tar.gz", .{target_name});
    tar_cmd.addArg(archive_name);
    tar_cmd.addArg("-C");
    tar_cmd.addArg(b.pathJoin(&.{ b.install_path, target_name }));
    tar_cmd.addArg(".");
    for (dependencies) |dep| {
        tar_cmd.step.dependOn(dep);
    }
    archive_step.dependOn(&tar_cmd.step);
}
fn setupTests(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    test_step: *std.Build.Step,
    sdk_module: *std.Build.Module,
    static_lib: *std.Build.Step.Compile,
) void {
    const zig_tests_mod = b.createModule(.{
        .root_source_file = b.path("tests/zig/test_core.zig"),
        .target = target,
        .optimize = optimize,
    });
    zig_tests_mod.addIncludePath(b.path("include"));
    zig_tests_mod.addImport("weon-sdk", sdk_module);
    const zig_tests = b.addTest(.{
        .root_module = zig_tests_mod,
    });
    zig_tests.root_module.link_libc = true;
    const run_zig_tests = b.addRunArtifact(zig_tests);
    run_zig_tests.skip_foreign_checks = true;
    test_step.dependOn(&run_zig_tests.step);
    const c_test_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    const c_test = b.addExecutable(.{
        .name = "test_c_integration",
        .root_module = c_test_mod,
    });
    c_test.addCSourceFile(.{ .file = b.path("tests/c/test_integration.c"), .flags = &[_][]const u8{} });
    c_test.addIncludePath(b.path("include"));
    c_test.linkLibrary(static_lib);
    c_test.root_module.link_libc = true;
    const run_c_test = b.addRunArtifact(c_test);
    run_c_test.skip_foreign_checks = true;
    test_step.dependOn(&run_c_test.step);
}