ISO_IMAGE = disk.iso

.PHONY: clean all run

all: $(ISO_IMAGE)

run: $(ISO_IMAGE)
	qemu-system-x86_64 -M q35 -m 2G -cdrom $(ISO_IMAGE)

limine:
	git clone https://github.com/limine-bootloader/limine.git --branch=v2.0-branch-binary --depth=1
	make -C limine

kernel:
	$(MAKE) -C src/kernel

libc:
	$(MAKE) -C src/libc

$(ISO_IMAGE): limine libc kernel 
	rm -rf iso_root
	mkdir -p iso_root
	mkdir -p iso_root/boot
	mkdir -p iso_root/usr
	mkdir -p iso_root/usr/include
	mkdir -p iso_root/usr/lib
	cp build/kernel/kernel.elf \
		limine/limine.sys iso_root/boot/
	cp limine.cfg limine/limine-cd.bin limine/limine-eltorito-efi.bin iso_root/
	cp boot/* iso_root/boot/
	cp src/include iso_root/usr -rf 
	cp build/libc/*.a iso_root/usr/lib
	xorriso -as mkisofs -b limine-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-eltorito-efi.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		iso_root -o $(ISO_IMAGE)
	limine/limine-install $(ISO_IMAGE)
	rm -rf iso_root

clean:
	rm -f $(ISO_IMAGE)
	$(MAKE) -C src clean
