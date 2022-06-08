const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("p", "src/main.zig");
    exe.addPackagePath("table-helper", "libs/table-helper/table-helper.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    // const exe2 = b.addExecutable("program", "src/main.zig");
    // exe2.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const step = b.step("task", "do something");
    step.makeFn = myTask;
    b.default_step = step;

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

fn myTask(self: *std.build.Step) !void {
    std.debug.print("Hello!\n", .{});
    _ = self;
}
