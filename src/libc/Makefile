LIBC := ../../build/libc/libc.a

CC = clang -target x86_64-none-elf
AR = llvm-ar

CFLAGS ?= -Wall -Wextra -O0 -g -pipe

INTERNALCFLAGS  :=                 \
	-I../include                   \
	-I../include/fslc              \
	-nostdlib -std=gnu11           \
	-ffreestanding                 \
	-fno-stack-protector           \
	-mcmodel=kernel                \
	-MMD -fpie                     \
	-mabi=sysv                     \
	-mno-sse                       \
	-mno-sse2                      \
	-mno-red-zone

CFILES := $(shell find ./ -type f -name '*.c')
SFILES := $(shell find ./ -type f -name '*.s')
OBJ    := $(patsubst %, ../../build/libc/%, $(CFILES:.c=.o))
SOBJ   := $(patsubst %, ../../build/libc/%, $(SFILES:.s=.s.o))

.PHONY: all clean

all: $(shell [ ! -d "../../build" ] || [ ! -d "../../build/libc" ]; mkdir -p ../../build/libc) $(LIBC)

$(LIBC): $(OBJ) $(SOBJ)
	$(AR) rcs $@ $(OBJ) $(SOBJ)

../../build/libc/%.o: %.c
	$(CC) $(CFLAGS) $(INTERNALCFLAGS) -c $< -o $@

../../build/libc/%.s.o: %.s
	nasm -felf64 $< -o $@

clean:
	rm -rf ../../build/libc
