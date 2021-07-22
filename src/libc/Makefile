# It is highly recommended to use a custom built cross toolchain to build a kernel.
# We are only using "cc" as a placeholder here. It may work by using
# the host system's toolchain, but this is not guaranteed.
CC = clang -fuse-ld=lld
 
# Likewise, "ld" here is just a placeholder and your mileage may vary if using the
# host's "ld".
LD = ld.lld
 
# User controllable CFLAGS.
CFLAGS = -Wall -Wextra -O2 -pipe -D__is_libc
 
# User controllable linker flags. We set none by default.
LDFLAGS =
 
# Internal C flags that should not be changed by the user.
INTERNALCFLAGS  :=         \
	-D__is_libc            \
	-I../include           \
	-std=gnu11             \
	-ffreestanding         \
	-fno-stack-protector   \
	-fno-pic -fpie         \
	-mno-80387             \
	-mno-mmx               \
	-mno-3dnow             \
	-mno-sse               \
	-mno-sse2              \
	-mno-red-zone
 
# Use find to glob all *.c files in the directory and extract the object names.
CFILES   := $(shell find ./ -type f -name '*.c')
OBJ      := $(CFILES:.c=.o)
LIBK_OBJ := $(OBJ:.o=.libk.o)
 
# Targets that do not actually build a file of the same name.
.PHONY: all clean
 
# Default target.
all: $(shell if [ ! -d "../../build" ] || [ ! -d "../../build/libc" ] || [ ! -d "../../build/libc/string" ] || [ ! -d "../../build/libc/stdlib" ] || [ ! -d "../../build/libc/stdio" ]; then \
	 mkdir -p ../../build/libc; \
	 mkdir -p ../../build/libc/string; \
	 mkdir -p ../../build/libc/stdlib; \
	 mkdir -p ../../build/libc/stdio; \
	 fi;) \
	libc.a libk.a

libc.a: $(OBJ)
	cd ../../build/libc; $(AR) rcs $@ $(OBJ)

libk.a: $(LIBK_OBJ)
	cd ../../build/libc; $(AR) rcs $@ $(LIBK_OBJ)

# Compilation rules for *.c files.
%.o: %.c
	$(CC) $(CFLAGS) -target x86_64-none-elf $(INTERNALCFLAGS) -c $< -o ../../build/libc/$@

%.libk.o: %.c
	$(CC) $(CFLAGS) -D__is_libk -target x86_64-none-elf $(INTERNALCFLAGS) -c $< -o ../../build/libc/$@
 
# Remove object files and the final executable.
clean:
	rm -rf ../../build/libc
