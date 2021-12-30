TRIPLE = x86_64-none-elf
PREFIX = llvm-

CC = clang -target x86_64-none-elf
LD = ld.lld
AR = $(PREFIX)ar
OBJCOPY = $(PREFIX)objcopy

toolchain:
clean-toolchain:
