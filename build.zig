const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const Arch = std.Target.Cpu.Arch;
const CrossTarget = std.zig.CrossTarget;

const deps = @import("deps.zig");

pub fn build(b: *Builder) !void {
    // const arch = b.option(Arch, "arch", "The CPU architecture to build for") orelse builtin.target.cpu.arch;
    const arch: Arch = .x86_64;
    const target = try genTarget(arch);

    const lara = try buildLara(b, target);
    const iso = try buildLimineIso(b, lara);
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
            target.cpu_features_sub.addFeature(@enumToInt(features.mmx));
            target.cpu_features_sub.addFeature(@enumToInt(features.sse));
            target.cpu_features_sub.addFeature(@enumToInt(features.sse2));
            target.cpu_features_sub.addFeature(@enumToInt(features.avx));
            target.cpu_features_sub.addFeature(@enumToInt(features.avx2));
            target.cpu_features_add.addFeature(@enumToInt(features.soft_float));
        },

        else => return error.UnsupportedArchitecture,
    }

    return target;
}

fn buildLara(b: *Builder, target: CrossTarget) !*std.build.LibExeObjStep {
    const mode = b.standardReleaseOptions();
    const lara = b.addExecutable("vmlara", switch (target.cpu_arch.?) {
        .x86_64 => "src/lara/arch/x86_64/main.zig",
        else => return error.UnsupportedArchitecture,
    });

    lara.setTarget(target);
    lara.setMainPkgPath("src/lara");
    lara.code_model = switch (target.cpu_arch.?) {
        .x86_64 => .kernel,
        .aarch64 => .small,
        else => return error.UnsupportedArchitecture,
    };
    //lara.addPackagePath("arch", switch (target.cpu_arch.?) {
    //    .x86_64 => "src/lara/arch/x86_64.zig",
    //    else => return error.UnsupportedArchitecture,
    //});
    lara.setBuildMode(mode);
    deps.addAllTo(lara);
    lara.setLinkerScriptPath(.{
        .path = switch (target.cpu_arch.?) {
            .x86_64 => "src/lara/arch/x86_64/linker.ld",
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
        std.mem.concat(b.allocator, u8, &[_][]const u8{
            "mkdir -p zig-out/iso/root && ",
            "make -C " ++ limine_path ++ " && ",
            "cp zig-out/bin/vmlara zig-out/iso/root && ",
            "cp src/lara/arch/x86_64/boot/limine.cfg zig-out/iso/root && ",
            "cp ", limine_path ++ "/limine.sys ",
                   limine_path ++ "/limine-cd.bin ",
                   limine_path ++ "/limine-cd-efi.bin ",
                   "zig-out/iso/root && ",
            "xorriso -as mkisofs -quiet -b limine-cd.bin ",
                "-no-emul-boot -boot-load-size 4 -boot-info-table ",
                "--efi-boot limine-cd-efi.bin ",
                "-efi-boot-part --efi-boot-image --protective-msdos-label ",
                "zig-out/iso/root -o zig-out/iso/faruos.iso && ",
            limine_path ++ "/" ++ limine_install ++ " " ++ "zig-out/iso/faruos.iso",
        // zig fmt: on
        }) catch unreachable,
    };

    const iso_cmd = b.addSystemCommand(cmd);
    iso_cmd.step.dependOn(&lara.install_step.?.step);

    const iso_step = b.step("iso", "Generate a bootable Limine ISO file");
    iso_step.dependOn(&iso_cmd.step);

    return iso_cmd;
}

fn runIsoQemu(b: *Builder, iso: *std.build.RunStep, arch: Arch) !*std.build.RunStep {
    const qemu_executable = switch (arch) {
        .x86_64 => "qemu-system-x86_64",
        else => return error.UnsupportedArchitecture,
    };
    const qemu_iso_args = &[_][]const u8{
        // zig fmt: off
        qemu_executable,
        //"-s", "-S",
        "-cpu", "max",
        "-smp", "2",
        "-M", "q35,accel=kvm:whpx:tcg",
        "-m", "2G",
        "-cdrom", "zig-out/iso/faruos.iso",
        "-boot", "d",
        "-serial", "stdio",
        // zig fmt: on
    };
    const qemu_iso_cmd = b.addSystemCommand(qemu_iso_args);
    qemu_iso_cmd.step.dependOn(&iso.step);

    const qemu_iso_step = b.step("run", "Boot ISO in qemu");
    qemu_iso_step.dependOn(&qemu_iso_cmd.step);

    return qemu_iso_cmd;
}
