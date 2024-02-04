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

    const ydin = try buildYdin(b, target, limine);
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

fn buildYdin(b: *std.Build, target: CrossTarget, limine: *std.Build.Dependency) !*std.Build.Step.Compile {
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
    ydin.setLinkerScriptPath(.{
        .path = switch (target.cpu_arch.?) {
            .x86_64 => "src/arch/x86_64/linker.ld",
            .aarch64 => "src/arch/aarch64/linker.ld",
            .riscv64 => "src/arch/riscv64/linker.ld",
            else => return error.UnsupportedArchitecture,
        },
    });
    ydin.root_module.addImport("limine", limine.module("limine"));

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
            "mkdir -p zig-out/iso/root/EFI/BOOT && ",
            "cp zig-out/bin/vmydin zig-out/iso/root && ",
            "cp src/arch/x86_64/boot/limine.cfg zig-out/iso/root && ",
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
            "-cpu", "max",
            "-smp", "2",
            "-M", "q35,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-cdrom", "zig-out/iso/kora.iso",
            "-bios", try edk2FileName(b, arch),
            "-boot", "d",
            "-serial", "stdio",
            // zig fmt: on
        },
        .aarch64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "max",
            "-smp", "2",
            "-M", "virt,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-cdrom", "zig-out/iso/kora.iso",
            "-bios", try edk2FileName(b, arch),
            "-boot", "d",
            "-serial", "stdio",
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

fn runYdinQemu(b: *std.Build, ydin: *std.Build.Step.Compile, arch: Arch) !*std.Build.Step.Run {
    const qemu_executable = switch (arch) {
        .x86_64 => "qemu-system-x86_64",
        .aarch64 => "qemu-system-aarch64",
        .riscv64 => "qemu-system-riscv64",
        else => return error.UnsupportedArchitecture,
    };

    const qemu_ydin_args = switch (arch) {
        .aarch64, .riscv64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "max",
            "-smp", "2",
            "-M", "virt,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-kernel", "zig-out/bin/vmydin",
            "-serial", "stdio",
            // zig fmt: on
        },
        else => return error.UnsupportedArchitecture,
    };

    const qemu_ydin_cmd = b.addSystemCommand(qemu_ydin_args);
    qemu_ydin_cmd.step.dependOn(&ydin.install_step.?.step);

    const qemu_ydin_step = b.step("run", "Boot Ydin in QEMU");
    qemu_ydin_step.dependOn(&qemu_ydin_cmd.step);

    return qemu_ydin_cmd;
}
