all: $(shell if [ ! -d "../../build" ] || [ ! -d "../../build/kernel" ] || [ ! -d "../../build/libc" ]; \
	 then mkdir -p ../../build/kernel ../../build/libc; \
	 fi;) \
	 kernel

.PHONY: kernel
kernel: 
	$(MAKE) -C kernel

.PHONY: libc
libc: kernel
	$(MAKE) -C libc

clean:
	rm -rf ../build
