TOOLCHAIN_BUILDDIR = $(BUILDDIR)/toolchain/build
TOOLCHAIN_PREFIXDIR = $(BUILDDIR)/toolchain/local

TOOLCHAIN_TARGET_TRIPLE = x86_64-unknown-faruos
TOOLCHAIN_PREFIX = $(TOOLCHAIN_PREFIXDIR)/bin/$(TOOLCHAIN_TARGET_TRIPLE)-

CC = $(TOOLCHAIN_PREFIX)gcc
LD = $(TOOLCHAIN_PREFIX)ld
AR = $(TOOLCHAIN_PREFIX)ar
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy

LDFLAGS += -L$(TOOLCHAIN_PREFIXDIR)/lib -lgcc

BINUTILS_VERSION = 2.37
BINUTILS_SHA256 = 820d9724f020a3e69cb337893a0b63c2db161dadcb0e06fc11dc29eb1e84a32c
BINUTILS_FILE = binutils-$(BINUTILS_VERSION).tar.xz
BINUTILS_URL = https://ftp.gnu.org/gnu/binutils/$(BINUTILS_FILE)
GCC_VERSION = 11.2.0
GCC_SHA256 = d08edc536b54c372a1010ff6619dd274c0f1603aa49212ba20f7aa2cda36fa8b
GCC_FILE = gcc-$(GCC_VERSION).tar.xz
GCC_URL = https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/$(GCC_FILE)

toolchain: mktoolchaindir \
	$(TOOLCHAIN_BUILDDIR)/binutils/src $(TOOLCHAIN_BUILDDIR)/gcc/src \
	$(TOOLCHAIN_BUILDDIR)/binutils/build/Makefile $(TOOLCHAIN_BUILDDIR)/binutils/.built \
	#$(TOOLCHAIN_BUILDDIR)/gcc/build/Makefile $(TOOLCHAIN_BUILDDIR)/gcc/.built \
	#$(LD) $(CC)

clean-toolchain:
	@rm -rf $(BUILDDIR)/toolchain

mktoolchaindir:
	@mkdir -p $(TOOLCHAIN_BUILDDIR) $(TOOLCHAIN_PREFIXDIR) || true

$(TOOLCHAIN_BUILDDIR)/$(BINUTILS_FILE):
	@echo -e "[TOOLCHAIN]\tDownloading Binutils tarball"
	@curl $(BINUTILS_URL) -O --output-dir $(TOOLCHAIN_BUILDDIR)
	@echo "$(BINUTILS_SHA256)  $@" | sha256sum --check > /dev/null || \
		{ echo -e "[TOOLCHAIN]\tError: Binutils tarball checksum didn't match"; exit 1; }
	@echo -e "[TOOLCHAIN]\tBinutils tarball checksum matched"

$(TOOLCHAIN_BUILDDIR)/$(GCC_FILE):
	@echo -e "[TOOLCHAIN]\tDownloading GCC tarball"
	@curl $(GCC_URL) -O --output-dir $(TOOLCHAIN_BUILDDIR)
	@echo "$(GCC_SHA256)  $@" | sha256sum --check > /dev/null || \
		{ echo -e "[TOOLCHAIN]\tError: GCC tarball SHA256 checksum didn't match"; exit 1; }
	@echo -e "[TOOLCHAIN]\tGCC tarball checksum matched"

$(TOOLCHAIN_BUILDDIR)/binutils/src: $(TOOLCHAIN_BUILDDIR)/$(BINUTILS_FILE)
	@mkdir -p $(TOOLCHAIN_BUILDDIR)/binutils/{build,src} || true
	@echo -e "[TOOLCHAIN]\tExtracting Binutils tarball"
	@tar xJf $< -C $(TOOLCHAIN_BUILDDIR)/binutils/src --strip-components=1
	@patch -p1 --dir $(TOOLCHAIN_BUILDDIR)/binutils/src < make/toolchain/gcc/binutils.patch > /dev/null

$(TOOLCHAIN_BUILDDIR)/gcc/src: $(TOOLCHAIN_BUILDDIR)/$(GCC_FILE)
	@mkdir -p $(TOOLCHAIN_BUILDDIR)/gcc/{build,src} || true
	@echo -e "[TOOLCHAIN]\tExtracting GCC tarball"
	@tar xJf $< -C $(TOOLCHAIN_BUILDDIR)/gcc/src --strip-components=1
	@patch -p1 --dir $(TOOLCHAIN_BUILDDIR)/gcc/src < make/toolchain/gcc/gcc.patch > /dev/null

$(TOOLCHAIN_BUILDDIR)/binutils/build/Makefile: $(TOOLCHAIN_BUILDDIR)/binutils/src
	@echo -e "[TOOLCHAIN]\tConfiguring Binutils"
	@cd $(TOOLCHAIN_BUILDDIR)/binutils/build && ../src/configure \
		--target $(TOOLCHAIN_TARGET_TRIPLE) --prefix $(TOOLCHAIN_PREFIXDIR) \
		--with-sysroot --disable-nls --disable-werror

$(TOOLCHAIN_BUILDDIR)/gcc/build/Makefile: $(TOOLCHAIN_BUILDDIR)/binutils/build/Makefile $(TOOLCHAIN_BUILDDIR)/gcc/src
	@echo -e "[TOOLCHAIN]\tConfiguring GCC"
	@cd $(TOOLCHAIN_BUILDDIR)/gcc/src && ../src/contrib/download_prerequisites
	@cd $(TOOLCHAIN_BUILDDIR)/gcc/build && ../src/configure \
		--target $(TOOLCHAIN_TARGET_TRIPLE) --prefix $(TOOLCHAIN_PREFIXDIR) \
		--disable-nls --enable-languages=c,c++ --without-headers

$(TOOLCHAIN_BUILDDIR)/binutils/.built: $(TOOLCHAIN_BUILDDIR)/binutils/build/Makefile
	@echo -e "[TOOLCHAIN]\tBuilding Binutils"
	@touch $(TOOLCHAIN_BUILDDIR)/binutils/.built
	+@cd $(TOOLCHAIN_BUILDDIR)/binutils/build && $(MAKE)

$(TOOLCHAIN_BUILDDIR)/gcc/.built: $(TOOLCHAIN_BUILDDIR)/binutils/.built $(TOOLCHAIN_BUILDDIR)/gcc/build/Makefile
	@echo -e "[TOOLCHAIN]\tBuilding GCC"
	@touch $(TOOLCHAIN_BUILDDIR)/gcc/.built
	+@cd $(TOOLCHAIN_BUILDDIR)/gcc/build && $(MAKE) \
		all-gcc target-libgcc all-target-libstdc++-v3

$(LD): $(TOOLCHAIN_BUILDDIR)/binutils/.built
	@echo -e "[TOOLCHAIN]\tInstalling Binutils"
	+@cd $(TOOLCHAIN_BUILDDIR)/binutils/build && $(MAKE) install

$(CC): $(TOOLCHAIN_BUILDDIR)/gcc/.built
	@echo -e "[TOOLCHAIN]\tInstalling GCC"
	+@cd $(TOOLCHAIN_BUILDDIR)/gcc/build && $(MAKE) \
		install-gcc install-libgcc install-libstdc++-v3
