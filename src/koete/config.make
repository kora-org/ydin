LIBKOETE := $(BUILDDIR)/koete/libkoete.a

KOETE_CFILES := $(shell find $(SRCDIR)/koete -name *.c)
KOETE_ASMFILES := $(shell find $(SRCDIR)/koete -name *.s)
KOETE_OBJ := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KOETE_CFILES:.c=.o))
KOETE_ASMOBJ := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KOETE_ASMFILES:.s=.s.o))
KOETE_DEPS := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KOETE_CFILES:.c=.d))
KOETE_ASMDEPS := $(patsubst $(SRCDIR)/%, $(BUILDDIR)/%, $(KOETE_ASMFILES:.s=.s.d))

koete: $(LIBKOETE)

$(LIBKOETE): $(KOETE_OBJ) $(KOETE_ASMOBJ)
	@echo "[AR]\t\t$(@:$(BUILDDIR)/koete/%=%)"
	@$(AR) rcs $@ $(KOETE_OBJ) $(KOETE_ASMOBJ)
	@ln -fs $@ $(@:libkoete.a=libc.a)

-include $(KOETE_DEPS) $(KOETE_ASMDEPS)

$(BUILDDIR)/koete/%.o: $(SRCDIR)/koete/%.c
	@echo "[CC]\t\t$(<:$(SRCDIR)/%=%)"
	@$(CC) $(CFLAGS) $(CHARDFLAGS) -c $< -o $@

$(BUILDDIR)/koete/%.s.o: $(SRCDIR)/koete/%.s
	@echo "[AS]\t\t$(<:$(SRCDIR)/%=%)"
	@$(AS) -felf64 -g -F dwarf $< -o $@

clean-koete:
	@rm -rf $(BUILDDIR)/koete
