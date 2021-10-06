ISO_IMAGE = build/faruos.iso

.PHONY: all run clean

all: $(ISO_IMAGE)

run: $(ISO_IMAGE)
	qemu-system-x86_64 -M q35 -m 2G -cdrom $(ISO_IMAGE)

limine:
	make -C external/limine

libc:
	make -C src/libc

kernel: libc
	make -C src/kernel

$(ISO_IMAGE): limine kernel
	@rm -rf build/sysroot
	@cp -r src/sysroot build/sysroot
	cp build/kernel/kernel.elf external/limine/limine.sys build/sysroot/boot
	cp external/limine/limine-cd.bin external/limine/limine-eltorito-efi.bin build/sysroot
	xorriso -as mkisofs -b limine-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-eltorito-efi.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		build/sysroot -o $(ISO_IMAGE)
	external/limine/limine-install $(ISO_IMAGE)
	@rm -rf build/sysroot

clean:
	rm -f $(ISO_IMAGE)
	$(MAKE) -C src/kernel clean
