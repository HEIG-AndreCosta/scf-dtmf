# scf-dtmf

## Getting started

### Prerequisites

- `arm-linux-gnueabihf-` toolchain in your PATH

1. Build the kernel

```bash
git submodule update --init
cd linux
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- socfpga_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
cd ..
```

2. Build the ITB image and add it to the boot partition of your sdcard

```bash
cd image
mkimage -f de1soc.its de1soc.itb
# Assuming your sdcard is mounted in /run/media/<username>/BOOT
# Modify the path accordingly
cp de1soc.itb /run/media/$(whoami)/de1soc.itb
cd ..
```

2. Build the driver

```bash
cd driver
make
cd ..
```

3. Build the user-space application

```bash
cd dtmf
cmake -DCMAKE_TOOLCHAIN_FILE=arm-linux-gnueabihf.cmake -B build -S .
cmake --build build -j$(nproc)
cd ..
```

