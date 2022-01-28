TRIPLE = x86_64-none-elf
PREFIX = llvm-

CC = clang -target x86_64-none-elf
LD = ld.lld
AR = $(PREFIX)ar
OBJCOPY = $(PREFIX)objcopy

LDFLAGS += -L$(CURDIR)/make/toolchain/llvm -lgcc

toolchain:
clean-toolchain:
