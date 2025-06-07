#include <assert.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

#define BUS_PHYS_ADDR		 0xFF200000
#define RAM_PHYS_ADDR		 0x100000

#define MAP_SIZE		 0xA000
#define MAP_MASK		 (MAP_SIZE - 1)

#define SLAVE_REG(addr, x)	 (((uint8_t *)addr) + x)
#define SLAVE_CONSTANT_REG(addr) SLAVE_REG(addr, 0x00)
#define SLAVE_TEST_REG(addr)	 SLAVE_REG(addr, 0x04)
/*#define SLAVE_TEST_REG(addr)	 SLAVE_REG(addr, 0x08)*/

#define SLAVE_EXPECTED_CONSTANT	 0XCAFE1234

#define SLAVE_BASE_MEM(addr)	 SLAVE_REG(addr, 0x40)
#define SLAVE_BASE_ADDR		 0x7000
#define MEM_BASE_ADDR		 0x8000
#define MEM_SIZE		 0x2000

uint8_t read8(void *addr)
{
	return *(uint8_t *)addr;
}

uint16_t read16(void *addr)
{
	return *(uint16_t *)addr;
}

void write8(void *addr, uint8_t value)
{
	*((uint8_t *)addr) = value;
}

void write16(void *addr, uint16_t value)
{
	*((uint16_t *)addr) = value;
}

uint32_t read32(void *addr)
{
	return *(uint32_t *)addr;
}
void write32(void *addr, uint32_t value)
{
	*((uint32_t *)addr) = value;
}

bool read_and_write32(void *addr, uint32_t value)
{
	write32(addr, value);
	const uint32_t x = read32(addr);
	printf("Wrote %#8x and read back %#8x\n", value, x);
	return x == value;
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

bool test_read_write_register(void *base_addr)
{
	const uint32_t wrote_value = 0x12345678;
	write32(SLAVE_TEST_REG(base_addr), wrote_value);
	uint32_t read_value = read32(SLAVE_TEST_REG(base_addr));
	bool ok = read_value == wrote_value;

	if (!ok) {
		fprintf(stderr,
			"Error reading back test register. Expected %08X but got %08X\n",
			wrote_value, read_value);
	}
	printf("Test read write register %s\n", ok ? "OK" : "KO");
	fflush(stdout);
	return true;
}

bool test_write_read_memory(void *base_addr)
{
	bool ok = true;
	for (size_t i = 0; i < MEM_SIZE; i += 4) {
		write32(base_addr + i, i);
	}
	for (size_t i = 0; i < MEM_SIZE; i += 4) {
		const uint32_t expected = i;
		uint32_t x = read32(base_addr + i);
		if (x != expected) {
			printf("%#04lx: Expected %#08x Got: %#08x\n", i,
			       expected, x);
			ok = false;
		}
	}

	for (size_t i = 0; i < MEM_SIZE; i += 2) {
		write16(base_addr + i, i & 0xFFFF);
	}
	for (size_t i = 0; i < MEM_SIZE; i += 2) {
		const uint32_t expected = i & 0xFFFF;
		uint16_t x = read16(base_addr + i);
		if (x != (i & 0xFFFF)) {
			printf("%#04lx: Expected %#08x Got: %#08x\n", i,
			       expected, x);
			ok = false;
		}
	}

	for (size_t i = 0; i < MEM_SIZE; i++) {
		write8(base_addr + i, i & 0xFF);
	}
	for (size_t i = 0; i < MEM_SIZE; i++) {
		const uint32_t expected = i & 0xFF;
		uint8_t x = read8(base_addr + i);
		if (x != expected) {
			printf("%#04lx: Expected %#08x Got: %#08x\n", i,
			       expected, x);
			ok = false;
		}
	}
	printf("Testing memory write read: %s\n", ok ? "OK" : "KO");
	fflush(stdout);
	return ok;
}
void dump_mem_registers(void *reg_base)
{
	const uint32_t rd_addr = read32(reg_base + 20);
	const uint32_t rd_ben = read32(reg_base + 24);
	const uint32_t rd_count = read32(reg_base + 28);
	const uint32_t wr_addr = read32(reg_base + 32);
	const uint32_t wr_ben = read32(reg_base + 36);
	const uint32_t wr_count = read32(reg_base + 40);

	printf("Last RD - Offset %#06x Byte Enable %#03x Total Count %u \n",
	       rd_addr, rd_ben, rd_count);
	printf("Last WR - Offset %#06x Byte Enable %#03x Total Count %u \n",
	       wr_addr, wr_ben, wr_count);
}
void dump_mem(void *reg_base, void *mem_addr)
{
	for (size_t i = 0x0000; i < 0x1000; i++) {
		const uint32_t x = read8(mem_addr + i);
		printf("%#08lx: %#08x\n", i, x);
	}
}

int main(void)
{
	unsigned long read_result, writeval;
	int access_type = 'w';
	int ret = EXIT_SUCCESS;

	int fd = open("/dev/mem", O_RDWR | O_SYNC);
	assert(fd != -1);

	printf("/dev/mem opened.\n");
	fflush(stdout);

	void *bus_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED,
			      fd, BUS_PHYS_ADDR & ~MAP_MASK);
	assert(bus_base != MAP_FAILED);

#if 0
	void *ram_map = mmap(0, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd,
			     RAM_PHYS_ADDR & ~MAP_MASK);
	assert(ram_map != MAP_FAILED);
#endif

	void *reg_base = bus_base + SLAVE_BASE_ADDR;
	void *mem_base = bus_base + MEM_BASE_ADDR;

	printf("Memory mapped at address %p.\n", reg_base);

	if (!test_read_constant(reg_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}

	if (!test_read_write_register(reg_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}
	if (!test_write_read_memory(mem_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}

err:
	fflush(stdout);
	if (munmap((void *)reg_base, MAP_SIZE) < 0) {
		fprintf(stderr, "Failed to unmap memory");
	}
	close(fd);
	return 0;
}
