MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))

KERNELDIR := $(MKFILE_DIR)../linux
TOOLCHAIN := arm-none-linux-gnueabihf-

TOOLCHAIN := $(shell \
	if which arm-none-linux-gnueabihf-gcc >/dev/null 2>&1; then \
		echo "arm-none-linux-gnueabihf-"; \
	elif which arm-linux-gnueabihf-gcc >/dev/null 2>&1; then \
		echo "arm-linux-gnueabihf-"; \
	else \
		echo ""; \
	fi)

ifeq ($(TOOLCHAIN),)
	$(error No suitable ARM toolchain found. Please download arm-none-linux-gnueabihf-gcc from 'https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz?rev=302e8e98351048d18b6f5b45d472f406&hash=B981F1567677321994BE1231441CB60C7274BB3D')
endif

obj-m := access.o

PWD := $(shell pwd)
WARN := -W -Wall -Wextra -Wstrict-prototypes -Wmissing-prototypes

access:
	@echo "Building with kernel sources in $(KERNELDIR)"
	$(MAKE) ARCH=arm CROSS_COMPILE=$(TOOLCHAIN) -C $(KERNELDIR) M=$(PWD) $(WARN)
	rm -rf *.o *~ core .depend .*.cmd *.mod.c .tmp_versions modules.order Module.symvers *.mod *.a

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions modules.order Module.symvers *.mod *.a
