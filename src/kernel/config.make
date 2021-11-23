KERNEL := $(BUILDDIR)/kernel/kernel.elf

KERNEL_CFILES := $(shell find $(SRCDIR)/kernel -name *.c)
KERNEL_ASMFILES := $(shell find $(SRCDIR)/kernel -name *.s)
KERNEL_OBJ := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KERNEL_CFILES:.c=.o))
KERNEL_ASMOBJ := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KERNEL_ASMFILES:.s=.s.o))

kernel: $(KERNEL)

$(KERNEL): $(KERNEL_OBJ) $(KERNEL_ASMOBJ)
	@echo "[LD]\t\t$(@:$(BUILDDIR)/kernel/%=%)"
	@$(LD) $(KERNEL_OBJ) $(KERNEL_ASMOBJ) $(LDFLAGS) $(LDHARDFLAGS) -T$(SRCDIR)/kernel/linker.ld -o $@

$(BUILDDIR)/kernel/%.o: $(SRCDIR)/kernel/%.c
	@echo "[CC]\t\t$(<:$(SRCDIR)/%=%)"
	@$(CC) $(CFLAGS) $(CHARDFLAGS) -c $< -o $@

$(BUILDDIR)/kernel/%.s.o: $(SRCDIR)/kernel/%.s
	@echo "[AS]\t\t$(<:$(SRCDIR)/%=%)"
	@$(AS) -felf64 -g -F dwarf $< -o $@

clean-kernel:
	@rm -rf $(BUILDDIR)/kernel
