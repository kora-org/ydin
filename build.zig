const std = @import("std");
const builtin = @import("builtin");
const Arch = std.Target.Cpu.Arch;
const CrossTarget = std.zig.CrossTarget;

const kora_version = std.SemanticVersion{
    .major = 0,
    .minor = 1,
    .patch = 0,
};

pub fn build(b: *std.Build) !void {
    const arch = b.option(Arch, "arch", "The CPU architecture to build for") orelse .x86_64;
    const target = try genTarget(arch);
    const limine = b.dependency("limine", .{});
    const limine_bootloader = b.dependency("limine_bootloader", .{});
    const uacpi = b.dependency("uacpi", .{});

    const ydin = try buildYdin(b, target, limine, uacpi);
    const iso = try buildLimineIso(b, ydin, limine_bootloader);
    const qemu = try runIsoQemu(b, iso, arch);
    _ = qemu;
}

fn genTarget(arch: Arch) !CrossTarget {
    var target = CrossTarget{
        .cpu_arch = arch,
        .os_tag = .freestanding,
        .abi = .none,
    };

    switch (arch) {
        .x86_64 => {
            const features = std.Target.x86.Feature;
            target.cpu_features_sub.addFeature(@intFromEnum(features.mmx));
            target.cpu_features_sub.addFeature(@intFromEnum(features.sse));
            target.cpu_features_sub.addFeature(@intFromEnum(features.sse2));
            target.cpu_features_sub.addFeature(@intFromEnum(features.avx));
            target.cpu_features_sub.addFeature(@intFromEnum(features.avx2));
            target.cpu_features_add.addFeature(@intFromEnum(features.soft_float));
        },
        .aarch64, .riscv64 => {},
        else => return error.UnsupportedArchitecture,
    }

    return target;
}

fn buildYdin(b: *std.Build, target: CrossTarget, limine: *std.Build.Dependency, uacpi: *std.Build.Dependency) !*std.Build.Step.Compile {
    const optimize = b.standardOptimizeOption(.{});
    const exe_options = b.addOptions();

    // From https://github.com/zigtools/zls
    const version = v: {
        const version_string = b.fmt("{d}.{d}.{d}", .{ kora_version.major, kora_version.minor, kora_version.patch });
        const build_root_path = b.build_root.path orelse ".";

        var code: u8 = undefined;
        const git_describe_untrimmed = b.runAllowFail(&[_][]const u8{
            "git", "-C", build_root_path, "describe", "--match", "*.*.*", "--tags",
        }, &code, .Ignore) catch break :v version_string;

        const git_describe = std.mem.trim(u8, git_describe_untrimmed, " \n\r");

        switch (std.mem.count(u8, git_describe, "-")) {
            0 => {
                // Tagged release version (e.g. 0.10.0).
                std.debug.assert(std.mem.eql(u8, git_describe, version_string)); // tagged release must match version string
                break :v version_string;
            },
            2 => {
                // Untagged development build (e.g. 0.10.0-dev.216+34ce200).
                var it = std.mem.split(u8, git_describe, "-");
                const tagged_ancestor = it.first();
                const commit_height = it.next().?;
                const commit_id = it.next().?;

                const ancestor_ver = try std.SemanticVersion.parse(tagged_ancestor);
                std.debug.assert(kora_version.order(ancestor_ver) == .gt); // version must be greater than its previous version
                std.debug.assert(std.mem.startsWith(u8, commit_id, "g")); // commit hash is prefixed with a 'g'

                break :v b.fmt("{s}-dev.{s}+{s}", .{ version_string, commit_height, commit_id[1..] });
            },
            else => {
                std.debug.print("Unexpected 'git describe' output: '{s}'\n", .{git_describe});
                std.process.exit(1);
            },
        }
    };

    exe_options.addOption([:0]const u8, "version", b.allocator.dupeZ(u8, version) catch "0.1.0-dev");

    const ydin = b.addExecutable(.{
        .name = "vmydin",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .code_model = switch (target.cpu_arch.?) {
            .x86_64 => .kernel,
            .aarch64 => .small,
            .riscv64 => .medium,
            else => return error.UnsupportedArchitecture,
        },
    });
    ydin.root_module.addOptions("build_options", exe_options);
    ydin.setLinkerScriptPath(.{ .path = "src/linker.ld" });
    ydin.root_module.addImport("limine", limine.module("limine"));
    ydin.addIncludePath(.{ .path = "src/uacpi" });
    ydin.addIncludePath(uacpi.path("include"));
    const root_dir = b.pathFromRoot(".");
    ydin.addCSourceFiles(.{
        .files = &[_][]const u8{
            "src/uacpi/printf.c",
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/tables.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/types.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/uacpi.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/utilities.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/interpreter.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/opcodes.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/namespace.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/stdlib.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/shareable.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/opregion.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/default_handlers.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/io.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/notify.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/sleep.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/registers.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/resources.c").getPath(b)),
            try std.fs.path.relative(b.allocator, root_dir, uacpi.path("source/event.c").getPath(b)),
        },
        .flags = &[_][]const u8{
            "-ffreestanding",
            "-nostdlib",
            "-mno-red-zone",
            "-DUACPI_OVERRIDE_STDLIB",
            "-DUACPI_SIZED_FREES",
        },
    });

    b.installArtifact(ydin);
    return ydin;
}

fn buildLimineIso(b: *std.Build, ydin: *std.Build.Step.Compile, limine: *std.Build.Dependency) !*std.Build.Step.Run {
    _ = ydin;
    const limine_path = limine.path(".");
    const target = b.standardTargetOptions(.{});
    const limine_exe = b.addExecutable(.{
        .name = "limine-deploy",
        .target = target,
        .optimize = .ReleaseSafe,
    });
    limine_exe.addCSourceFile(.{ .file = limine.path("limine.c"), .flags = &[_][]const u8{"-std=c99"} });
    limine_exe.linkLibC();
    const limine_exe_run = b.addRunArtifact(limine_exe);

    const cmd = &[_][]const u8{
        // zig fmt: off
        "/bin/sh", "-c",
        try std.mem.concat(b.allocator, u8, &[_][]const u8{
            "rm -rf zig-out/iso/root && ",
            "mkdir -p zig-out/iso/root/EFI/BOOT && ",
            "cp zig-out/bin/vmydin zig-out/iso/root && ",
            "cp src/boot/limine.cfg zig-out/iso/root && ",
            "cp ", limine_path.getPath(b), "/limine-bios.sys ",
                   limine_path.getPath(b), "/limine-bios-cd.bin ",
                   limine_path.getPath(b), "/limine-uefi-cd.bin ",
                   "zig-out/iso/root && ",
            "cp ", limine_path.getPath(b), "/BOOTX64.EFI ",
                   limine_path.getPath(b), "/BOOTAA64.EFI ",
                   limine_path.getPath(b), "/BOOTRISCV64.EFI ",
                   "zig-out/iso/root/EFI/BOOT && ",
            "xorriso -as mkisofs -quiet -b limine-bios-cd.bin ",
                "-no-emul-boot -boot-load-size 4 -boot-info-table ",
                "--efi-boot limine-uefi-cd.bin ",
                "-efi-boot-part --efi-boot-image --protective-msdos-label ",
                "zig-out/iso/root -o zig-out/iso/kora.iso",
        }),
        // zig fmt: on
    };

    const iso_cmd = b.addSystemCommand(cmd);
    iso_cmd.step.dependOn(b.getInstallStep());

    _ = limine_exe_run.addOutputFileArg("kora.iso");
    limine_exe_run.step.dependOn(&iso_cmd.step);

    const iso_step = b.step("iso", "Generate a bootable Limine ISO file");
    iso_step.dependOn(&limine_exe_run.step);

    return iso_cmd;
}

fn downloadEdk2(b: *std.Build, arch: Arch) !void {
    const link = switch (arch) {
        .x86_64 => "https://retrage.github.io/edk2-nightly/bin/RELEASEX64_OVMF.fd",
        .aarch64 => "https://retrage.github.io/edk2-nightly/bin/RELEASEAARCH64_QEMU_EFI.fd",
        .riscv64 => "https://retrage.github.io/edk2-nightly/bin/RELEASERISCV64_VIRT.fd",
        else => return error.UnsupportedArchitecture,
    };

    const cmd = &[_][]const u8{ "curl", link, "-Lo", try edk2FileName(b, arch) };
    var child_proc = std.ChildProcess.init(cmd, b.allocator);
    try child_proc.spawn();
    const ret_val = try child_proc.wait();
    try std.testing.expectEqual(ret_val, std.ChildProcess.Term{ .Exited = 0 });
}

fn edk2FileName(b: *std.Build, arch: Arch) ![]const u8 {
    return std.mem.concat(b.allocator, u8, &[_][]const u8{ "zig-cache/edk2-", @tagName(arch), ".fd" });
}

fn runIsoQemu(b: *std.Build, iso: *std.Build.Step.Run, arch: Arch) !*std.Build.Step.Run {
    _ = std.fs.cwd().statFile(try edk2FileName(b, arch)) catch try downloadEdk2(b, arch);

    const qemu_executable = switch (arch) {
        .x86_64 => "qemu-system-x86_64",
        .aarch64 => "qemu-system-aarch64",
        .riscv64 => "qemu-system-riscv64",
        else => return error.UnsupportedArchitecture,
    };

    const qemu_iso_args = switch (arch) {
        .x86_64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "host",
            "-smp", "4",
            "-M", "q35,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-cdrom", "zig-out/iso/kora.iso",
            "-bios", try edk2FileName(b, arch),
            "-boot", "d",
            "-serial", "stdio",
            "-display", "none",
            "-no-reboot",
            // zig fmt: on
        },
        .aarch64, .riscv64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "max",
            "-smp", "4",
            "-M", "virt,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-cdrom", "zig-out/iso/kora.iso",
            "-bios", try edk2FileName(b, arch),
            "-boot", "d",
            "-serial", "stdio",
            "-display", "none",
            "-no-reboot",
            "-no-shutdown",
            // zig fmt: on
        },
        else => return error.UnsupportedArchitecture,
    };

    const qemu_iso_cmd = b.addSystemCommand(qemu_iso_args);
    qemu_iso_cmd.step.dependOn(&iso.step);

    const qemu_iso_step = b.step("run", "Boot ISO in QEMU");
    qemu_iso_step.dependOn(&qemu_iso_cmd.step);

    return qemu_iso_cmd;
}
