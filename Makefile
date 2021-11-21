SRCDIR = ./src
BUILDDIR = ./build
EXTERNALDIR = ./external

ISO = $(BUILDDIR)/faruos.iso

CC = clang -target x86_64-none-elf
AS = nasm
LD = ld.lld
AR = llvm-ar
QEMU = qemu-system-x86_64

CFLAGS ?= -O0 -gdwarf -pipe
ASFLAGS ?=
LDFLAGS ?=
QEMUFLAGS ?= -M q35

LDHARDFLAGS := \
	-nostdlib -static \
	-L$(BUILDDIR)/koete -lkoete

CHARDFLAGS := \
	-I$(SRCDIR)/include \
	-I$(EXTERNALDIR)/stivale \
	-nostdlib -std=gnu11 \
	-ffreestanding -fno-pic \
	-fno-stack-protector \
	-mcmodel=kernel -MMD \
	-mno-red-zone

.DEFAULT_GOAL: all
.PHONY: all koete kernel clean clean-koete clean-kernel

all: mkbuilddir $(ISO)

mkbuilddir:
	@mkdir -p $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(shell find $(SRCDIR)/koete -type d))
	@mkdir -p $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(shell find $(SRCDIR)/kernel -type d))

include $(SRCDIR)/koete/config.make
include $(SRCDIR)/kernel/config.make

run: $(ISO)
	@echo "[QEMU]\t\t$(<:build/%=%)"
	@$(QEMU) -m 4G -no-reboot -no-shutdown $(QEMUFLAGS) -cdrom $(ISO)

limine:
	@$(MAKE) --no-print-directory -C external/limine

$(ISO): limine koete kernel
	@rm -rf build/sysroot
	@cp -r src/sysroot build/sysroot
	@cp build/kernel/kernel.elf external/limine/limine.sys build/sysroot/boot
	@cp external/limine/limine-cd.bin external/limine/limine-eltorito-efi.bin build/sysroot
	@echo "[XORRISO]\t$(@:build/%=%)"
	@xorriso -as mkisofs -b limine-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-eltorito-efi.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		build/sysroot -o $(ISO) >/dev/null 2>&1
	@echo "[LIMINE]\t$(@:build/%=%)"
	@external/limine/limine-install $(ISO) >/dev/null 2>&1
	@rm -rf build/sysroot

clean: clean-kernel clean-koete
	@$(RM)r $(ISO)
	@$(RM)r $(BUILDDIR)
