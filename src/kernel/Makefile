KERNEL := ../../build/kernel/kernel.elf

CC = clang -target x86_64-none-elf
AS = nasm
LD = ld.lld

CFLAGS ?= -O0 -gdwarf -pipe
LDFLAGS ?=

INTERNALLDFLAGS := \
	-Tlinker.ld \
	-nostdlib \
	-zmax-page-size=0x1000 \
	-static \
	-L../../build/libc -lc \
	-ztext -zmuldefs

INTERNALCFLAGS := \
	-I../include \
	-I../../external/stivale \
	-nostdlib -std=gnu11 \
	-ffreestanding -fno-pic \
	-fno-stack-protector \
	-mcmodel=kernel -MMD \
	-mno-red-zone

CFILES := $(wildcard *.c */*.c)
SFILES := $(wildcard *.s */*.s)
OBJ := $(patsubst %, ../../build/kernel/%, $(CFILES:.c=.o))
SOBJ := $(patsubst %, ../../build/kernel/%, $(SFILES:.s=.s.o))

.PHONY: all clean

all: checkdir $(KERNEL)

checkdir:
	@if [ ! -d "../../build" ] || [ ! -d "../../build/kernel" ]; then \
		mkdir -p $(patsubst %, ../../build/kernel/%, $(sort $(dir $(wildcard */)))); \
	fi

$(KERNEL): $(OBJ) $(SOBJ)
	@echo "[LD]\t\t$(@:../../build/kernel/%=%)"
	@$(LD) $(OBJ) $(SOBJ) $(LDFLAGS) $(INTERNALLDFLAGS) -o $@

../../build/kernel/%.o: %.c
	@echo "[CC]\t\t$<"
	@$(CC) $(CFLAGS) $(INTERNALCFLAGS) -c $< -o $@

../../build/kernel/%.s.o: %.s
	@echo "[AS]\t\t$<"
	@$(AS) -felf64 -g -F dwarf $< -o $@

clean:
	@rm -rf ../../build/kernel
