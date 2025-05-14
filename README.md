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

2. Build the driver

```bash
cd driver
make
cd ..
```

3. Build the user-space application

```bash
cd dtmf
cmake -B build -S .
cmake --build build -j$(nproc)
cd ..
```

