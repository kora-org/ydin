LIBKOETE := ../../build/koete/libkoete.a

CC = clang -target x86_64-none-elf
AS = nasm
AR = llvm-ar

CFLAGS ?= -O0 -g -pipe

INTERNALCFLAGS := \
	-I../include \
	-I../../external/stivale \
	-nostdlib -std=gnu11 \
	-ffreestanding -fno-pic \
	-fno-stack-protector \
	-mcmodel=kernel -MMD \
	-mno-red-zone

CFILES := $(wildcard *.c */*.c */*/*.c)
SFILES := $(wildcard *.s */*.s */*/*.s)
OBJ := $(patsubst %, ../../build/koete/%, $(CFILES:.c=.o))
SOBJ := $(patsubst %, ../../build/koete/%, $(SFILES:.s=.s.o))

.PHONY: all clean

all: checkdir $(LIBKOETE)

checkdir:
	@if [ ! -d "../../build" ] || [ ! -d "../../build/koete" ]; then \
		mkdir -p $(patsubst %, ../../build/koete/%, $(sort $(dir $(wildcard */*)))); \
	fi

$(LIBKOETE): $(OBJ) $(SOBJ)
	@echo "[AR]\t\t$(@:../../build/koete/%=%)"
	@$(AR) rcs $@ $(OBJ) $(SOBJ)
	@ln -s $@ $(@:libkoete.a=libc.a)

../../build/koete/%.o: %.c
	@echo "[CC]\t\t$<"
	@$(CC) $(CFLAGS) $(INTERNALCFLAGS) -c $< -o $@

../../build/koete/%.s.o: %.s
	@echo "[AS]\t\t$<"
	@$(AS) -felf64 -g -F dwarf $< -o $@

clean:
	@rm -rf ../../build/koete
