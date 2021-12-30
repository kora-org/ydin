SHELL = bash

SRCDIR = $(CURDIR)/src
BUILDDIR = $(CURDIR)/build
EXTERNALDIR = $(CURDIR)/external

BRANCH := $(shell git branch --show-current)
TAGCOMMIT := $(shell git rev-list --abbrev-commit --tags --max-count=1)
TAG := $(shell git describe --abbrev=0 --tags $(TAGCOMMIT) 2>/dev/null || true)
COMMIT := $(shell git rev-parse --short HEAD)
DATE := $(shell git log -1 --format=%cd --date=format:"%Y%m%d")
VERSION := $(TAG:v%=%)
ifneq ($(TAGCOMMIT), $(COMMIT))
	VERSION := $(VERSION)-dev-$(BRANCH)-$(COMMIT)
endif
ifeq ($(TAG:v%=%),)
	VERSION := git-$(BRANCH)-$(COMMIT)
endif

ISO = $(BUILDDIR)/faruos.iso
TOOLCHAIN = llvm

AS = nasm
QEMU = qemu-system-x86_64

CFLAGS ?= -Og -gdwarf -pipe
ASFLAGS ?=
LDFLAGS ?=
QEMUFLAGS ?=
QEMUMEMSIZE ?= 2G

LDHARDFLAGS := \
	-nostdlib -static \
	-L$(BUILDDIR)/koete -lkoete \
	-zmax-page-size=0x1000

CHARDFLAGS := \
	-I$(SRCDIR)/include \
	-I$(EXTERNALDIR)/stivale \
	-nostdlib -std=gnu11 \
	-ffreestanding -fno-pic \
	-fno-stack-protector \
	-fsanitize=undefined \
	-mcmodel=kernel -MMD -MP \
	-mno-red-zone -D__faruos__ \
	-D__faruos_version__='"$(VERSION)"' \
	-D__faruos_build__='"$(COMMIT)"' \
	-D__faruos_date__='"$(DATE)"'

.DEFAULT_GOAL: all
.PHONY: all toolchain koete kernel clean clean-toolchain clean-koete clean-kernel

all: toolchain mkbuilddir $(ISO)

mkbuilddir:
	@mkdir -p $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(shell find $(SRCDIR)/koete -type d))
	@mkdir -p $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(shell find $(SRCDIR)/kernel -type d))

include make/toolchain/$(TOOLCHAIN)/config.make
include $(SRCDIR)/koete/config.make
include $(SRCDIR)/kernel/config.make

run: all
	@echo -e "[QEMU]\t\t$(ISO:$(BUILDDIR)/%=%)"
	@$(QEMU) -m $(QEMUMEMSIZE) -no-reboot -no-shutdown $(QEMUFLAGS) -cdrom $(ISO)

limine:
	@$(MAKE) --no-print-directory -C external/limine

$(ISO): limine koete kernel
	@rm -rf $(BUILDDIR)/sysroot
	@cp -r $(SRCDIR)/sysroot $(BUILDDIR)/sysroot
	@cp $(BUILDDIR)/kernel/kernel.elf $(EXTERNALDIR)/limine/limine.sys $(BUILDDIR)/sysroot/boot
	@cp $(EXTERNALDIR)/limine/limine-cd.bin $(EXTERNALDIR)/limine/limine-eltorito-efi.bin $(BUILDDIR)/sysroot
	@echo -e "[XORRISO]\t$(@:$(BUILDDIR)/%=%)"
	@xorriso -as mkisofs -b limine-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-eltorito-efi.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		$(BUILDDIR)/sysroot -o $(ISO) >/dev/null 2>&1
	@echo -e "[LIMINE]\t$(@:$(BUILDDIR)/%=%)"
	@external/limine/limine-install $(ISO) >/dev/null 2>&1

clean: clean-kernel clean-koete
	@$(RM)r $(ISO)
	@$(RM)r $(BUILDDIR)
