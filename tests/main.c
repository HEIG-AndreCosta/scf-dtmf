#include <assert.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

#define BUS_PHYS_ADDR		 0xFF200000

#define MEM_REGION_SIZE		 0x2000
#define MAP_SIZE		 0x8000
#define MAP_MASK		 (MAP_SIZE - 1)

#define SLAVE_REG(addr, x)	 (((uint8_t *)addr) + x)
#define SLAVE_CONSTANT_REG(addr) SLAVE_REG(addr, 0x18)

#define SLAVE_EXPECTED_CONSTANT	 0XCAFE4321

#define SLAVE_BASE_MEM(addr)	 SLAVE_REG(addr, 0x40)
#define SLAVE_BASE_ADDR		 0x4000

uint8_t read8(void *addr)
{
	return *(uint8_t *)addr;
}

uint16_t read16(void *addr)
{
	return *(uint16_t *)addr;
}

uint32_t read32(void *addr)
{
	/*printf("Reading at %p\n", addr);*/
	return *(volatile uint32_t *)addr;
}

void write8(void *addr, uint8_t value)
{
	*((uint8_t *)addr) = value;
}

void write16(void *addr, uint16_t value)
{
	*((uint16_t *)addr) = value;
}

void write32(void *addr, uint32_t value)
{
	*((volatile uint32_t *)addr) = value;
}

bool test_read_constant(void *base_addr)
{
	printf("Reading constant\n");
	uint32_t constant = read32(SLAVE_CONSTANT_REG(base_addr));

	if (constant != SLAVE_EXPECTED_CONSTANT) {
		fprintf(stderr,
			"Error reading slave constant. Expected %08X but got %08X\n",
			SLAVE_EXPECTED_CONSTANT, constant);
		return false;
	}

	printf("Reading constant OK\n");
	fflush(stdout);
	return true;
}
bool test_write_read_memory(void *base_addr)
{
	printf("Testing memory write read\n");
	for (size_t i = 0x2000; i < 0x4000; i += 4) {
		write32(base_addr + i, 0x1000 + i);
	}
	bool ok = true;
	for (size_t i = 0x2000; i < 0x4000; i += 4) {
		uint32_t x = read32(base_addr + i);
		if (x != 0x1000 + i) {
			printf("%#04lx: Expected %#08lx Got: %#08x\n", i,
			       0x1000 + i, x);
			ok = false;
		}
	}
	printf("Testing memory write read: %s\n", ok ? "OK" : "KO");
	fflush(stdout);
	return ok;
}
void dump_mem(void *base_addr)
{
	for (size_t i = 0x0000; i < 0x4000; i += 4) {
		const uint32_t x = read32(base_addr + i);
		if (x != 0) {
			printf("%#04lx: %#08x\n", i, x);
		}
	}

	/*for (size_t i = 0x0000; i < 0x2100; i += 4) {*/
	/*	printf("%#04lx: %#08x\n", i, read32(base_addr + i));*/
	/*}*/
}

int main(void)
{
	void *map_base, *virt_addr;
	unsigned long read_result, writeval;
	int access_type = 'w';
	int ret = EXIT_SUCCESS;

	int fd = open("/dev/mem", O_RDWR | O_SYNC);
	assert(fd != -1);

	printf("/dev/mem opened.\n");
	fflush(stdout);

	map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd,
			BUS_PHYS_ADDR & ~MAP_MASK);

	assert(map_base != MAP_FAILED);

	map_base += SLAVE_BASE_ADDR;

	printf("Memory mapped at address %p.\n", map_base);

	if (!test_read_constant(map_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}
#if 0
	if (!test_write_read_memory(map_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}

	write32(map_base + 0x2000, 0x2000);

	// Read it back multiple times
	for (int i = 0; i < 5; i++) {
		uint32_t val = read32(map_base + 0x2000);
		printf("Read %d: 0x%08x\n", i, val);
	}
	/*write32(map_base + 0x2004, 0x2004);*/
#endif

	// Read it back multiple times
	for (int i = 0; i < 5; i++) {
		uint32_t val = read32(map_base + 0x2004);
		printf("Read %d: 0x%08x\n", i, val);
	}
	/*write32(map_base + 0x2000, 0x12345678);*/
	/*write32(map_base + 0x2004, 0xABCDEF00);*/
	/**/
	/*uint32_t read1 = read32(map_base + 0x2000);*/
	/*uint32_t read2 = read32(map_base + 0x2000); // Read same address again*/
	/**/
	/*printf("Address 0x2000: First read = 0x%08x, Second read = 0x%08x\n",*/
	/*       read1, read2);*/

	/*write32(map_base + 0x3ff4, 0x00202020);*/
	/*dump_mem(map_base);*/
	/*dump_mem(map_base);*/
	/*printf("%#08x\n", read32(map_base + 0x3ff0));*/
err:
	fflush(stdout);
	if (munmap(map_base, MAP_SIZE) < 0) {
		fprintf(stderr, "Failed to unmap memory");
	}
	close(fd);
	return 0;
}
