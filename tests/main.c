#include <assert.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

#define BUS_PHYS_ADDR			    0xFF200000
#define RAM_PHYS_ADDR			    0x100000

#define BUS_MAP_SIZE			    0x4000
#define BUS_MAP_MASK			    (BUS_MAP_SIZE - 1)

#define RAM_MAP_SIZE			    0x1000
#define RAM_MAP_MASK			    (RAM_MAP_SIZE - 1)

#define SLAVE_REG(addr, x)		    (((uint8_t *)addr) + x)
#define SLAVE_CONSTANT_REG(addr)	    SLAVE_REG(addr, 0x00)
#define SLAVE_TEST_REG(addr)		    SLAVE_REG(addr, 0x04)
/*#define SLAVE_TEST_REG(addr)	 SLAVE_REG(addr, 0x08)*/

#define SLAVE_EXPECTED_CONSTANT		    0XCAFE1234

#define SLAVE_BASE_MEM(addr)		    SLAVE_REG(addr, 0x40)
#define DMA_BASE_ADDR			    0x0000
#define SLAVE_BASE_ADDR			    0x1000
#define MEM_BASE_ADDR			    0x2000
#define MEM_SIZE			    0x2000

#define MSGDMA_CSR_STATUS_REG		    0x00
#define MSGDMA_CSR_CTRL_REG		    0x04
#define MSGDMA_STATUS_BUSY		    (1 << 0)
#define MSGDMA_STATUS_RESETTING		    (1 << 6)
#define MSGDMA_STATUS_IRQ		    (1 << 9)

#define MSGDMA_DESC_CTRL_TX_COMPLETE_IRQ_EN (1 << 14)
#define MSGDMA_DESC_CTRL_GO		    (1 << 31)

#define MSGDMA_DESC_READ_ADDR_REG	    0x20
#define MSGDMA_DESC_WRITE_ADDR_REG	    0x24
#define MSGDMA_DESC_LEN_REG		    0x28
#define MSGDMA_DESC_CTRL_REG		    0x2C

uint8_t read8(volatile void *addr)
{
	return *(volatile uint8_t *)addr;
}

uint16_t read16(volatile void *addr)
{
	return *(volatile uint16_t *)addr;
}

void write8(volatile void *addr, uint8_t value)
{
	*((volatile uint8_t *)addr) = value;
}

void write16(volatile void *addr, uint16_t value)
{
	*((volatile uint16_t *)addr) = value;
}

uint32_t read32(volatile void *addr)
{
	return *(volatile uint32_t *)addr;
}
void write32(volatile void *addr, uint32_t value)
{
	*((volatile uint32_t *)addr) = value;
}

bool read_and_write32(volatile void *addr, uint32_t value)
{
	write32(addr, value);
	const uint32_t x = read32(addr);
	printf("Wrote %#8x and read back %#8x\n", value, x);
	return x == value;
}
bool test_read_constant(volatile void *base_addr)
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

bool test_read_write_register(volatile void *base_addr)
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

bool test_write_read_memory(volatile void *base_addr)
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
void dump_mem_registers(volatile void *reg_base)
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
void dump_mem(volatile void *reg_base, void *mem_addr)
{
	for (size_t i = 0x0000; i < 0x1000; i++) {
		const uint32_t x = read8(mem_addr + i);
		printf("%#08lx: %#08x\n", i, x);
	}
}

bool test_dma_write(volatile void *ram_map, void *dma_map, void *mem_map)
{
	printf("Test dma write\n");

	read_and_write32(mem_map, 0xdeadbeef);
	const uint32_t expected_value = 0x12345678;
	// set random value in sdram
	if (!read_and_write32(ram_map, expected_value)) {
		fprintf(stderr, "Failed to write random value to SDRAM\n");
		return false;
	}

	// reset dma
	write32(dma_map + MSGDMA_CSR_CTRL_REG, 0x2);
	printf("Waiting for dma module to finish resetting\n");
	fflush(stdout);

	while (read32(dma_map + MSGDMA_CSR_STATUS_REG) &
	       MSGDMA_STATUS_RESETTING)
		;

	printf("Dma module reset\n");
	// configure descriptor
	write32(dma_map + MSGDMA_DESC_READ_ADDR_REG, RAM_PHYS_ADDR);
	write32(dma_map + MSGDMA_DESC_WRITE_ADDR_REG,
		BUS_PHYS_ADDR + MEM_BASE_ADDR);
	write32(dma_map + MSGDMA_DESC_LEN_REG, 4);

	printf("Starting transfer\n");
	fflush(stdout);

	uint32_t status_reg = read32(dma_map + MSGDMA_CSR_STATUS_REG);
	printf("%#08x\n", status_reg);
	fflush(stdout);
	// go
	write32(dma_map + MSGDMA_DESC_CTRL_REG,
		MSGDMA_DESC_CTRL_GO | MSGDMA_DESC_CTRL_TX_COMPLETE_IRQ_EN);

	printf("Waiting for transfer to complete\n");

	status_reg = read32(dma_map + MSGDMA_CSR_STATUS_REG);
	printf("%#08x\n", status_reg);
	fflush(stdout);
	fflush(stdout);
	while (1) {
		uint32_t status_reg = read32(dma_map + MSGDMA_CSR_STATUS_REG);
		printf("%#08x\n", status_reg);
		fflush(stdout);
		if (status_reg & MSGDMA_STATUS_IRQ) {
			break;
		}
		usleep(1000000);
	}

	write32(dma_map + MSGDMA_CSR_STATUS_REG,
		MSGDMA_DESC_CTRL_TX_COMPLETE_IRQ_EN);

	printf("Transfer complete\n");
	fflush(stdout);
	uint32_t value = read32(mem_map);
	if (value != expected_value) {
		fprintf(stderr,
			"Expected value not found in target memory address. Expected %#08x but got %#08x",
			expected_value, value);
		return false;
	}

	return true;
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

	volatile void *bus_base = mmap(0, BUS_MAP_SIZE, PROT_READ | PROT_WRITE,
				       MAP_SHARED, fd,
				       BUS_PHYS_ADDR & ~BUS_MAP_MASK);
	assert(bus_base != MAP_FAILED);

	volatile void *ram_map = mmap(0, RAM_MAP_SIZE, PROT_READ | PROT_WRITE,
				      MAP_SHARED, fd,
				      RAM_PHYS_ADDR & ~RAM_MAP_MASK);
	assert(ram_map != MAP_FAILED);

	volatile void *reg_base = bus_base + SLAVE_BASE_ADDR;
	volatile void *mem_base = bus_base + MEM_BASE_ADDR;
	volatile void *dma_map = bus_base + DMA_BASE_ADDR;

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
#if 0
	if (!test_dma_write(ram_map, dma_map, mem_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}
#endif

err:
	fflush(stdout);
	if (munmap((void *)bus_base, BUS_MAP_SIZE) < 0) {
		fprintf(stderr, "Failed to unmap memory");
	}

	if (munmap((void *)ram_map, RAM_MAP_SIZE) < 0) {
		fprintf(stderr, "Failed to unmap memory");
	}
	close(fd);
	return 0;
}
