const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const Arch = std.Target.Cpu.Arch;
const CrossTarget = std.zig.CrossTarget;
const deps = @import("deps.zig");

const kora_version = std.SemanticVersion{
    .major = 0,
    .minor = 1,
    .patch = 0,
};

pub fn build(b: *Builder) !void {
    const arch = b.option(Arch, "arch", "The CPU architecture to build for") orelse .x86_64;
    const target = try genTarget(arch);

    const ydin = try buildYdin(b, target);
    const iso = try buildLimineIso(b, ydin);
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

fn buildYdin(b: *Builder, target: CrossTarget) !*std.build.LibExeObjStep {
    const optimize = b.standardOptimizeOption(.{});
    const exe_options = b.addOptions();

    // From zls
    const version = v: {
        const version_string = b.fmt("{d}.{d}.{d}", .{ kora_version.major, kora_version.minor, kora_version.patch });

        var code: u8 = undefined;
        const git_describe_untrimmed = b.execAllowFail(&[_][]const u8{
            "git", "-C", b.build_root.path.?, "describe", "--match", "*.*.*", "--tags",
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

                const ancestor_ver = std.SemanticVersion.parse(tagged_ancestor) catch unreachable;
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
        .root_source_file = .{
            .path = switch (target.cpu_arch.?) {
                .x86_64 => "src/arch/x86_64/main.zig",
                .aarch64 => "src/arch/aarch64/main.zig",
                .riscv64 => "src/arch/riscv64/main.zig",
                else => return error.UnsupportedArchitecture,
            },
        },
        .target = target,
        .optimize = optimize,
    });

    ydin.code_model = switch (target.cpu_arch.?) {
        .x86_64 => .kernel,
        .aarch64 => .small,
        .riscv64 => .medium,
        else => return error.UnsupportedArchitecture,
    };
    //ydin.addAnonymousModule("arch", .{
    //    .source_file = .{
    //        .path = switch (target.cpu_arch.?) {
    //            .x86_64 => "src/arch/x86_64.zig",
    //            else => return error.UnsupportedArchitecture,
    //        },
    //    },
    //});
    deps.addAllTo(ydin);
    ydin.addOptions("build_options", exe_options);
    ydin.setLinkerScriptPath(.{
        .path = switch (target.cpu_arch.?) {
            .x86_64 => "src/arch/x86_64/linker.ld",
            .aarch64 => "src/arch/aarch64/linker.ld",
            .riscv64 => "src/arch/riscv64/linker.ld",
            else => return error.UnsupportedArchitecture,
        },
    });
    b.installArtifact(ydin);

    return ydin;
}

fn buildLimineIso(b: *Builder, ydin: *std.build.LibExeObjStep) !*std.build.RunStep {
    _ = ydin;
    const limine_path = deps.package_data._limine.directory;
    const limine_install = switch (builtin.os.tag) {
        .linux => "limine-deploy",
        .windows => "limine-deploy.exe",
        else => return error.UnsupportedOs,
    };

    const cmd = &[_][]const u8{
        // zig fmt: off
        "/bin/sh", "-c",
        try std.mem.concat(b.allocator, u8, &[_][]const u8{
            "mkdir -p zig-out/iso/root/EFI/BOOT && ",
            "make -C ", limine_path, " && ",
            "cp zig-out/bin/vmydin zig-out/iso/root && ",
            "cp src/arch/x86_64/boot/limine.cfg zig-out/iso/root && ",
            "cp ", limine_path, "/limine.sys ",
                   limine_path, "/limine-cd.bin ",
                   limine_path, "/limine-cd-efi.bin ",
                   "zig-out/iso/root && ",
            "cp ", limine_path, "/BOOTX64.EFI ",
                   limine_path, "/BOOTAA64.EFI ",
                   limine_path, "/BOOTRISCV64.EFI ",
                   "zig-out/iso/root/EFI/BOOT && ",
            "xorriso -as mkisofs -quiet -b limine-cd.bin ",
                "-no-emul-boot -boot-load-size 4 -boot-info-table ",
                "--efi-boot limine-cd-efi.bin ",
                "-efi-boot-part --efi-boot-image --protective-msdos-label ",
                "zig-out/iso/root -o zig-out/iso/kora.iso && ",
            limine_path, "/", limine_install, " ", "zig-out/iso/kora.iso",
        // zig fmt: on
        }),
    };

    const iso_cmd = b.addSystemCommand(cmd);
    iso_cmd.step.dependOn(b.getInstallStep());

    const iso_step = b.step("iso", "Generate a bootable Limine ISO file");
    iso_step.dependOn(&iso_cmd.step);

    return iso_cmd;
}

fn downloadEdk2(b: *Builder, arch: Arch) !void {
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
    try std.testing.expectEqual(ret_val, .{ .Exited = 0 });
}

fn edk2FileName(b: *Builder, arch: Arch) ![]const u8 {
    return std.mem.concat(b.allocator, u8, &[_][]const u8{ "zig-cache/edk2-", @tagName(arch), ".fd" });
}

fn runIsoQemu(b: *Builder, iso: *std.build.RunStep, arch: Arch) !*std.build.RunStep {
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

fn runYdinQemu(b: *Builder, ydin: *std.build.LibExeObjStep, arch: Arch) !*std.build.RunStep {
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
