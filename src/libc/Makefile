LIBC := ../../build/libc/libc.a

CC = clang -target x86_64-none-elf
AS = nasm
AR = llvm-ar

CFLAGS ?= -O0 -g -pipe

INTERNALCFLAGS  :=             \
	-I../include           \
	-I../include/fslibc    \
	-nostdlib -std=gnu11   \
	-ffreestanding -fwrapv \
	-fno-stack-protector   \
	-mcmodel=kernel -MMD   \
	-fpie -mno-red-zone

CFILES := $(wildcard *.c */*.c)
SFILES := $(wildcard *.s */*.s)
OBJ    := $(patsubst %, ../../build/libc/%, $(CFILES:.c=.o))
SOBJ   := $(patsubst %, ../../build/libc/%, $(SFILES:.s=.s.o))

.PHONY: all clean

all: checkdir $(LIBC)

checkdir:
	@if [ ! -d "../../build" ] || [ ! -d "../../build/libc" ]; then \
		mkdir -p ../../build/libc/; \
	fi

$(LIBC): $(OBJ) $(SOBJ)
	@echo "[AR]\t\t$(@:../../build/libc/%=%)"
	@$(AR) rcs $@ $(OBJ) $(SOBJ)

../../build/libc/%.o: %.c
	@echo "[CC]\t\t$<"
	@$(CC) $(CFLAGS) $(INTERNALCFLAGS) -c $< -o $@

../../build/libc/%.s.o: %.s
	@echo "[AS]\t\t$<"
	@$(AS) -felf64 -g -F dwarf $< -o $@

clean:
	@rm -rf ../../build/libc
