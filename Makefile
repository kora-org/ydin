ISO = build/faruos.iso
QEMUFLAGS ?=

.PHONY: all run clean

all: $(ISO)

run: $(ISO)
	@echo "[QEMU]\t\t$(<:build/%=%)"
	@qemu-system-x86_64 -M q35 -m 2G -no-reboot -no-shutdown $(QEMUFLAGS) -cdrom $(ISO)

limine:
	@$(MAKE) --no-print-directory -C external/limine

koete:
	@$(MAKE) --no-print-directory -C src/koete

kernel: koete
	@$(MAKE) --no-print-directory -C src/kernel

$(ISO): limine kernel
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

clean:
	@rm -f $(ISO)
	@$(MAKE) --no-print-directory -C src/koete clean
	@$(MAKE) --no-print-directory -C src/kernel clean
