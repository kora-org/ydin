LIBC := ../../build/libc/libc.a

CC = clang -target x86_64-none-elf
AS = nasm
AR = llvm-ar

CFLAGS ?= -O0 -g -pipe

INTERNALCFLAGS  :=           \
	-I../include             \
	-I../include/fslibc      \
	-nostdlib -std=gnu11     \
	-ffreestanding -fwrapv   \
	-fno-stack-protector     \
	-mcmodel=kernel -MMD     \
	-fpie -mno-red-zone

CFILES := $(shell find ./ -type f -name '*.c')
SFILES := $(shell find ./ -type f -name '*.s')
OBJ    := $(patsubst %, ../../build/libc/%, $(CFILES:.c=.o))
SOBJ   := $(patsubst %, ../../build/libc/%, $(SFILES:.s=.s.o))

.PHONY: all clean

all: $(shell [ ! -d "../../build" ] || [ ! -d "../../build/libc" ]; mkdir -p ../../build/libc) $(LIBC)

$(LIBC): $(OBJ) $(SOBJ)
	@echo "  AR  $(@:../../build/libc/%=%)"
	@$(AR) rcs $@ $(OBJ) $(SOBJ)

../../build/libc/%.o: %.c
	@echo "  CC  $<"
	@$(CC) $(CFLAGS) $(INTERNALCFLAGS) -c $< -o $@

../../build/libc/%.s.o: %.s
	@echo "  AS  $<"
	@$(AS) -felf64 -g -F dwarf $< -o $@

clean:
	@rm -rf ../../build/libc
