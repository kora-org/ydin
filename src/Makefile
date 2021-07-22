all: $(shell if [ ! -d "../../build" ] || [ ! -d "../../build/kernel" ] || [ ! -d "../../build/libc" ]; \
	 then mkdir -p ../../build/kernel ../../build/libc; \
	 fi;) \
	 libc kernel

.PHONY: libc kernel

libc:
	$(MAKE) -C libc

kernel: libc
	$(MAKE) -C kernel

clean:
	rm -rf ../build
