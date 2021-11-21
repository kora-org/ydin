SRCDIR = src
BUILDDIR = build
EXTERNALDIR = external

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

run: all
	@echo "[QEMU]\t\t$(ISO:$(BUILDDIR)/%=%)"
	@$(QEMU) -m 4G -no-reboot -no-shutdown $(QEMUFLAGS) -cdrom $(ISO)

limine:
	@$(MAKE) --no-print-directory -C external/limine

$(ISO): limine koete kernel
	@rm -rf $(BUILDDIR)/sysroot
	@cp -r $(SRCDIR)/sysroot $(BUILDDIR)/sysroot
	@cp $(BUILDDIR)/kernel/kernel.elf $(EXTERNALDIR)/limine/limine.sys $(BUILDDIR)/sysroot/boot
	@cp $(EXTERNALDIR)/limine/limine-cd.bin $(EXTERNALDIR)/limine/limine-eltorito-efi.bin $(BUILDDIR)/sysroot
	@echo "[XORRISO]\t$(@:$(BUILDDIR)/%=%)"
	@xorriso -as mkisofs -b limine-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-eltorito-efi.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		$(BUILDDIR)/sysroot -o $(ISO) >/dev/null 2>&1
	@echo "[LIMINE]\t$(@:$(BUILDDIR)/%=%)"
	@external/limine/limine-install $(ISO) >/dev/null 2>&1

clean: clean-kernel clean-koete
	@$(RM)r $(ISO)
	@$(RM)r $(BUILDDIR)
