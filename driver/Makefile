MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))

KERNELDIR := $(MKFILE_DIR)../linux
TOOLCHAIN := arm-linux-gnueabihf-

obj-m := access.o

PWD := $(shell pwd)
WARN := -W -Wall -Wextra -Wstrict-prototypes -Wmissing-prototypes

access:
	@echo "Building with kernel sources in $(KERNELDIR)"
	$(MAKE) ARCH=arm CROSS_COMPILE=$(TOOLCHAIN) -C $(KERNELDIR) M=$(PWD) $(WARN)
	rm -rf *.o *~ core .depend .*.cmd *.mod.c .tmp_versions modules.order Module.symvers *.mod *.a

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions modules.order Module.symvers *.mod *.a
