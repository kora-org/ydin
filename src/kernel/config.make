KERNEL := $(BUILDDIR)/kernel/kernel.elf

KERNEL_CFILES := $(shell find $(SRCDIR)/kernel -name *.c)
KERNEL_ASMFILES := $(shell find $(SRCDIR)/kernel -name *.s)
KERNEL_OBJ := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KERNEL_CFILES:.c=.o))
KERNEL_ASMOBJ := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KERNEL_ASMFILES:.s=.s.o))
KERNEL_DEPS := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KERNEL_CFILES:.c=.d))
KERNEL_ASMDEPS := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KERNEL_ASMFILES:.s=.s.d))

kernel: $(KERNEL)

$(KERNEL): $(KERNEL_OBJ) $(KERNEL_ASMOBJ)
	@echo -e "[LD]\t\t$(@:$(BUILDDIR)/kernel/%=%)"
	@$(LD) $(KERNEL_OBJ) $(KERNEL_ASMOBJ) $(LDFLAGS) $(LDHARDFLAGS) -T$(SRCDIR)/kernel/linker.ld -o $@
	@python $(SRCDIR)/gensym.py $(KERNEL)
	@$(CC) $(CFLAGS) $(CHARDFLAGS) -c $(SRCDIR)/kernel/misc/symbols.c -o $(BUILDDIR)/kernel/misc/symbols.o
	@$(LD) $(KERNEL_OBJ) $(KERNEL_ASMOBJ) $(LDFLAGS) $(LDHARDFLAGS) -T$(SRCDIR)/kernel/linker.ld -o $@

-include $(KERNEL_DEPS) $(KERNEL_ASMDEPS)

$(BUILDDIR)/kernel/%.o: $(SRCDIR)/kernel/%.c
	@echo -e "[CC]\t\t$(<:$(SRCDIR)/%=%)"
	@$(CC) $(CFLAGS) $(CHARDFLAGS) -c $< -o $@

$(BUILDDIR)/kernel/%.s.o: $(SRCDIR)/kernel/%.s
	@echo -e "[AS]\t\t$(<:$(SRCDIR)/%=%)"
	@$(AS) -felf64 -g -Fdwarf -MD -MP $< -o $@

clean-kernel:
	@rm -rf $(BUILDDIR)/kernel