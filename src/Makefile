all: $(shell if [ ! -d "../../build" ] || [ ! -d "../../build/kernel" ] || [ ! -d "../../build/libc" ]; \
	 then mkdir -p ../../build/kernel ../../build/libc; \
	 fi;) \
	 libc kernel

.PHONY: libc kernel

kernel: libc
	$(MAKE) -C kernel

libc: 
	$(MAKE) -C libc

clean:
	rm -rf ../build
