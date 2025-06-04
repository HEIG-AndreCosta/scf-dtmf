KERNELDIR := /home/patrick/HEIG-VD/SCF/Labo/scf_2025/labo9/scf-dtmf/linux
TOOLCHAIN := /usr/bin/arm-linux-gnueabihf-

# Source files for DTMF application
SRCS := src/main.c src/buffer.c src/dtmf.c src/file.c src/wave.c src/utils.c src/fft.c src/dtmf_encoder.c src/dtmf_decoder.c src/fpga.c

# Object files
OBJS := $(SRCS:.c=.o)

PWD := $(shell pwd)
WARN := -W -Wall -Wextra -pedantic

CC := $(TOOLCHAIN)gcc
# Include paths for headers and driver
CFLAGS := -I../driver/ -I/usr/include $(WARN) -g

# Libraries - try to link libsndfile statically to avoid runtime issues
LDFLAGS := -lm

# Look for ARM version of libsndfile (change this line!)
SNDFILE_STATIC := /usr/arm-linux-gnueabihf/lib/libsndfile.a
# Fallback locations to check
SNDFILE_ALT1 := /usr/lib/arm-linux-gnueabihf/libsndfile.a
SNDFILE_ALT2 := /usr/local/arm-linux-gnueabihf/lib/libsndfile.a

# SNDFILE_DEPS := -lvorbisenc -lvorbis -lFLAC -logg -lopus
SNDFILE_DEPS :=
# Target executable
TARGET := dtmf_encdec

all: $(TARGET)

# Check multiple locations for ARM libsndfile
$(TARGET): $(OBJS)
	@echo "Linking $(TARGET) for ARM"
	@if [ -f "$(SNDFILE_STATIC)" ]; then \
		echo "Using ARM static libsndfile: $(SNDFILE_STATIC)"; \
		$(CC) $(OBJS) -o $@ $(SNDFILE_STATIC) $(SNDFILE_DEPS) $(LDFLAGS); \
	elif [ -f "$(SNDFILE_ALT1)" ]; then \
		echo "Using ARM static libsndfile: $(SNDFILE_ALT1)"; \
		$(CC) $(OBJS) -o $@ $(SNDFILE_ALT1) $(SNDFILE_DEPS) $(LDFLAGS); \
	elif [ -f "$(SNDFILE_ALT2)" ]; then \
		echo "Using ARM static libsndfile: $(SNDFILE_ALT2)"; \
		$(CC) $(OBJS) -o $@ $(SNDFILE_ALT2) $(SNDFILE_DEPS) $(LDFLAGS); \
	else \
		echo "No ARM static libsndfile found, using dynamic linking"; \
		$(CC) $(OBJS) -o $@ -lsndfile $(LDFLAGS); \
	fi
	@echo "Build complete. Architecture check:"
	file $(TARGET)

# Compile individual source files
src/%.o: src/%.c
	@echo "Compiling $< for ARM"
	$(CC) $(CFLAGS) -c $< -o $@

# Alternative: Force static linking of all libraries
static: $(OBJS)
	@echo "Linking $(TARGET) for ARM (fully static)"
	$(CC) -static $(OBJS) -o $(TARGET) -lsndfile -lFLAC -lvorbisenc -lvorbis -logg -lm
	@echo "Build complete. Architecture check:"
	file $(TARGET)

# Alternative: Dynamic linking (will need libraries on target)
dynamic: $(OBJS)
	@echo "Linking $(TARGET) for ARM (dynamic)"
	$(CC) $(OBJS) -o $(TARGET) -lsndfile $(LDFLAGS)
	@echo "Build complete. Architecture check:"
	file $(TARGET)

clean:
	@echo "Cleaning up build files"
	rm -rf $(OBJS) $(TARGET) *~ core .depend

install: $(TARGET)
	@echo "Copying $(TARGET) to DE1-SoC"
	scp $(TARGET) root@192.168.0.2:

# Install libsndfile on DE1-SoC if using dynamic linking
install-libs:
	@echo "Installing libsndfile on DE1-SoC"
	ssh root@192.168.0.2 "opkg update && opkg install libsndfile"

test: install
	@echo "Testing $(TARGET) on DE1-SoC"
	ssh root@192.168.0.2 "cd /tmp && ./$(TARGET)"

# Download and install libsndfile statically for cross-compilation
setup-sndfile:
	@echo "Setting up minimal static libsndfile for cross-compilation"
	wget -O /tmp/libsndfile-1.2.2.tar.xz https://github.com/libsndfile/libsndfile/releases/download/1.2.2/libsndfile-1.2.2.tar.xz
	cd /tmp && tar -xf libsndfile-1.2.2.tar.xz
	cd /tmp/libsndfile-1.2.2 && ./configure \
		--host=arm-linux-gnueabihf \
		--enable-static \
		--disable-shared \
		--prefix=/usr/arm-linux-gnueabihf \
		--disable-external-libs \
		--disable-mpeg \
		--disable-flac \
		--disable-ogg \
		--disable-vorbis \
		--disable-opus
	cd /tmp/libsndfile-1.2.2 && make -j8
	cd /tmp/libsndfile-1.2.2 && sudo make install
	@echo "Minimal static ARM libsndfile installed to /usr/arm-linux-gnueabihf"

.PHONY: all clean install test static dynamic setup-sndfile install-libs

# Show usage
help:
	@echo "Usage:"
	@echo "  make              - Build dtmf_encdec (tries static, falls back to dynamic)"
	@echo "  make static       - Force static linking (needs all deps)"
	@echo "  make dynamic      - Force dynamic linking"
	@echo "  make setup-sndfile- Download and build static ARM libsndfile"
	@echo "  make clean        - Clean build files"
	@echo "  make install      - Copy executable to DE1-SoC"
	@echo "  make install-libs - Install libsndfile on DE1-SoC (for dynamic builds)"
	@echo "  make test         - Build, install and test on DE1-SoC"
	@echo ""
	@echo "If linking fails:"
	@echo "  1. Try 'make setup-sndfile' first"
	@echo "  2. Then 'make static'"
	@echo "  3. Or use 'make dynamic' + 'make install-libs'"