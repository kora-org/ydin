const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const Arch = std.Target.Cpu.Arch;
const CrossTarget = std.zig.CrossTarget;
const deps = @import("deps.zig");

const faruos_version = std.builtin.Version{
    .major = 0,
    .minor = 1,
    .patch = 0,
};

pub fn build(b: *Builder) !void {
    const arch = b.option(Arch, "arch", "The CPU architecture to build for") orelse .x86_64;
    const target = try genTarget(arch);

    const lara = try buildLara(b, target);
    if ((arch == .x86_64) or (arch == .aarch64)) {
        const iso = try buildLimineIso(b, lara);
        const qemu = try runIsoQemu(b, iso, arch);
        _ = qemu;
    } else {
        const qemu = try runLaraQemu(b, lara, arch);
        _ = qemu;
    }
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
            target.cpu_features_sub.addFeature(@enumToInt(features.mmx));
            target.cpu_features_sub.addFeature(@enumToInt(features.sse));
            target.cpu_features_sub.addFeature(@enumToInt(features.sse2));
            target.cpu_features_sub.addFeature(@enumToInt(features.avx));
            target.cpu_features_sub.addFeature(@enumToInt(features.avx2));
            target.cpu_features_add.addFeature(@enumToInt(features.soft_float));
        },
        .aarch64, .riscv64 => {},
        else => return error.UnsupportedArchitecture,
    }

    return target;
}

fn buildLara(b: *Builder, target: CrossTarget) !*std.build.LibExeObjStep {
    const mode = b.standardReleaseOptions();
    const exe_options = b.addOptions();

    // From zls
    const version = v: {
        const version_string = b.fmt("{d}.{d}.{d}", .{ faruos_version.major, faruos_version.minor, faruos_version.patch });

        var code: u8 = undefined;
        const git_describe_untrimmed = b.execAllowFail(&[_][]const u8{
            "git", "-C", b.build_root, "describe", "--match", "*.*.*", "--tags",
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

                const ancestor_ver = std.builtin.Version.parse(tagged_ancestor) catch unreachable;
                std.debug.assert(faruos_version.order(ancestor_ver) == .gt); // version must be greater than its previous version
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

    const lara = b.addExecutable("vmlara", switch (target.cpu_arch.?) {
        .x86_64 => "src/lara/arch/x86_64/main.zig",
        .aarch64 => "src/lara/arch/aarch64/main.zig",
        .riscv64 => "src/lara/arch/riscv64/main.zig",
        else => return error.UnsupportedArchitecture,
    });

    lara.setTarget(target);
    lara.setMainPkgPath("src/lara");
    lara.code_model = switch (target.cpu_arch.?) {
        .x86_64 => .kernel,
        .aarch64 => .small,
        .riscv64 => .medium,
        else => return error.UnsupportedArchitecture,
    };
    //lara.addPackagePath("arch", switch (target.cpu_arch.?) {
    //    .x86_64 => "src/lara/arch/x86_64.zig",
    //    else => return error.UnsupportedArchitecture,
    //});
    lara.setBuildMode(mode);
    deps.addAllTo(lara);
    lara.addOptions("build_options", exe_options);
    lara.setLinkerScriptPath(.{
        .path = switch (target.cpu_arch.?) {
            .x86_64 => "src/lara/arch/x86_64/linker.ld",
            .aarch64 => "src/lara/arch/aarch64/linker.ld",
            .riscv64 => "src/lara/arch/riscv64/linker.ld",
            else => return error.UnsupportedArchitecture,
        },
    });
    lara.install();

    return lara;
}

fn buildLimineIso(b: *Builder, lara: *std.build.LibExeObjStep) !*std.build.RunStep {
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
            "make -C " ++ limine_path ++ " && ",
            "cp zig-out/bin/vmlara zig-out/iso/root && ",
            "cp src/lara/arch/x86_64/boot/limine.cfg zig-out/iso/root && ",
            "cp ", limine_path ++ "/limine.sys ",
                   limine_path ++ "/limine-cd.bin ",
                   limine_path ++ "/limine-cd-efi.bin ",
                   "zig-out/iso/root && ",
            "cp ", limine_path ++ "/BOOTX64.EFI ",
                   limine_path ++ "/BOOTAA64.EFI ",
                   "zig-out/iso/root/EFI/BOOT && ",
            "xorriso -as mkisofs -quiet -b limine-cd.bin ",
                "-no-emul-boot -boot-load-size 4 -boot-info-table ",
                "--efi-boot limine-cd-efi.bin ",
                "-efi-boot-part --efi-boot-image --protective-msdos-label ",
                "zig-out/iso/root -o zig-out/iso/faruos.iso && ",
            limine_path ++ "/" ++ limine_install ++ " " ++ "zig-out/iso/faruos.iso",
        // zig fmt: on
        }),
    };

    const iso_cmd = b.addSystemCommand(cmd);
    iso_cmd.step.dependOn(&lara.install_step.?.step);

    const iso_step = b.step("iso", "Generate a bootable Limine ISO file");
    iso_step.dependOn(&iso_cmd.step);

    return iso_cmd;
}

fn downloadEdk2(b: *Builder, arch: Arch) !void {
    const link = switch (arch) {
        .x86_64 => "https://retrage.github.io/edk2-nightly/bin/RELEASEX64_OVMF.fd",
        .aarch64 => "https://retrage.github.io/edk2-nightly/bin/RELEASEAARCH64_QEMU_EFI.fd",
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
            "-cdrom", "zig-out/iso/faruos.iso",
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
            "-cdrom", "zig-out/iso/faruos.iso",
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

fn runLaraQemu(b: *Builder, lara: *std.build.LibExeObjStep, arch: Arch) !*std.build.RunStep {
    const qemu_executable = switch (arch) {
        .x86_64 => "qemu-system-x86_64",
        .aarch64 => "qemu-system-aarch64",
        .riscv64 => "qemu-system-riscv64",
        else => return error.UnsupportedArchitecture,
    };

    const qemu_lara_args = switch (arch) {
        .aarch64, .riscv64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "max",
            "-smp", "2",
            "-M", "virt,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-kernel", "zig-out/bin/vmlara",
            "-serial", "stdio",
            // zig fmt: on
        },
        else => return error.UnsupportedArchitecture,
    };

    const qemu_lara_cmd = b.addSystemCommand(qemu_lara_args);
    qemu_lara_cmd.step.dependOn(&lara.install_step.?.step);

    const qemu_lara_step = b.step("run", "Boot Lara in QEMU");
    qemu_lara_step.dependOn(&qemu_lara_cmd.step);

    return qemu_lara_cmd;
}
