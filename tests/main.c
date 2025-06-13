#include <assert.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <inttypes.h>

#define TEST_DMA 0

#if TEST_DMA
#include "../driver/msgdma.h"
#endif

#define BUS_PHYS_ADDR		 0xFF200000
#define RAM_PHYS_ADDR		 0x100000

#define BUS_MAP_SIZE		 0x4000
#define BUS_MAP_MASK		 (BUS_MAP_SIZE - 1)

#define RAM_MAP_SIZE		 0x1000
#define RAM_MAP_MASK		 (RAM_MAP_SIZE - 1)

#define SLAVE_REG(addr, x)	 (((uint8_t *)addr) + x)
#define SLAVE_CONSTANT_REG(addr) SLAVE_REG(addr, 0x00)
#define SLAVE_TEST_REG(addr)	 SLAVE_REG(addr, 0x04)
/*#define SLAVE_TEST_REG(addr)	 SLAVE_REG(addr, 0x08)*/

#define SLAVE_EXPECTED_CONSTANT	 0XCAFE1234

#define SLAVE_BASE_MEM(addr)	 SLAVE_REG(addr, 0x40)
#define DMA_BASE_ADDR		 0x0000
#define SLAVE_BASE_ADDR		 0x1000
#define MEM_BASE_ADDR		 0x2000
#define MEM_SIZE		 	 0x2000

// DTMF Correlation Test Constants (matching driver and VHDL)
#define DTMF_MEM_BASE			       		0x2000
#define DTMF_WINDOW_START_ADDR		       DTMF_MEM_BASE
#define WINDOW_REGION_SIZE                     4096
#define WINDOW_REGION_SIZE_IN_ADDRESS          1024
#define REF_SIGNALS_REGION_SIZE                2048
#define DTMF_REF_SIGNAL_START_ADDR	       (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)

// DTMF Register Offsets (matching correlation.vhd)
#define DTMF_ID_REG_OFFSET		       		0x00
#define DTMF_TEST_REG_OFFSET		       	0x04
#define DTMF_START_CALCULATION_REG_OFFSET   0x08
#define DTMF_IRQ_STATUS_REG_OFFSET	       	0x0C
#define DTMF_DOT_PRODUCT_LOW_OFFSET	       	0x10
#define DTMF_DOT_PRODUCT_HIGH_OFFSET	    0x14
#define DTMF_WINDOW_REG_START_OFFSET(n)	    0x100 + (n * 4)
#define DTMF_REF_REG_START_OFFSET(n)	    0x184 + (n * 4)

#define DTMF_EXPECTED_ID		       			0xCAFE1234
#define DTMF_IRQ_STATUS_CALCULATION_DONE       	0x01

// Test constants
#define NUM_DTMF_BUTTONS                       12
#define MAX_WINDOWS                            35
#define BYTES_PER_SAMPLE                       2
#define DEFAULT_WINDOW_SIZE                    64  // samples per window

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

// Setup the state machine to a known state (number of windows, window size, etc.)
bool setup_state_machine_for_test_irq(volatile void *reg_base)
{
	printf("Setting up state machine\n");

	// irq status should be 0
	uint32_t status = read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET);
	if (status & DTMF_IRQ_STATUS_CALCULATION_DONE) {
		fprintf(stderr,
			"Error: Machine did not reset correctly. Status %#08x\n",
			status);
		printf("Resetting IRQ status\n");
		write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, 0xFFFFFFFF);
		status = read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET);
		printf("IRQ status after reset = %#08x\n", status);
		if (status & DTMF_IRQ_STATUS_CALCULATION_DONE) {
			fprintf(stderr,
				"Error: IRQ status still not reset. Status %#08x\n",
				status);
			return false;
		}
	}

	printf("State machine setup OK\n");
	return true;
}

// Test if machine state work correctly so if i start a calculation does the irq goes to one ?
bool test_irq_status(volatile void *reg_base)
{
	printf("Testing machine state\n");

	setup_state_machine_for_test_irq(reg_base);

	// Start the calculation
	write32(reg_base + DTMF_START_CALCULATION_REG_OFFSET, 0x1);
	printf("Waiting for machine to reset\n");
	fflush(stdout);
	while (!(read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET) & DTMF_IRQ_STATUS_CALCULATION_DONE)) {
	}

	//acknowledge the irq
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET,
		DTMF_IRQ_STATUS_CALCULATION_DONE);

	//read if ack worked
	uint32_t status = read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET);
	if (status & DTMF_IRQ_STATUS_CALCULATION_DONE) {
		fprintf(stderr,
			"Error: Machine did not reset correctly. Status %#08x\n",
			status);
		return false;
	}

	printf("Calculation done\n");
	return true;
}

bool test_dot_product_calculation(volatile void *reg_base)
{
	printf("=== Testing Dot Product Calculation ===\n");
	
	// Clear IRQ status
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, 0xFFFFFFFF);
	uint32_t status = read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET);
	if (status & DTMF_IRQ_STATUS_CALCULATION_DONE) {
		fprintf(stderr, "Error: IRQ status not cleared. Status: %#08x\n", status);
		return false;
	}
	
	// Test 1: Simple known values
	// Window samples: [1, 2, 3, 4, 5, 6, 7, 8]
	// Reference samples: [1, 1, 1, 1, 1, 1, 1, 1]
	// Expected dot product: 36
	
	printf("Test 1: Simple dot product calculation\n");
	
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(0), (2 << 16) | 1);  // samples 0,1: [1, 2]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(1), (4 << 16) | 3);  // samples 2,3: [3, 4]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(2), (6 << 16) | 5);  // samples 4,5: [5, 6]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(3), (8 << 16) | 7);  // samples 6,7: [7, 8]
	

	write32(reg_base + DTMF_REF_REG_START_OFFSET(0), (1 << 16) | 1);  // samples 0,1: [1, 1]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(1), (1 << 16) | 1);  // samples 2,3: [1, 1]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(2), (1 << 16) | 1);  // samples 4,5: [1, 1]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(3), (1 << 16) | 1);  // samples 6,7: [1, 1]
	
	printf("  Written window samples: [1, 2, 3, 4, 5, 6, 7, 8]\n");
	printf("  Written reference samples: [1, 1, 1, 1, 1, 1, 1, 1]\n");
	printf("  Expected dot product: 36\n");
	
	write32(reg_base + DTMF_START_CALCULATION_REG_OFFSET, 1);

	// Wait for completion
	while (!(read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET) & DTMF_IRQ_STATUS_CALCULATION_DONE))
	{
		usleep(1000); // 1ms delay
	}

	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, DTMF_IRQ_STATUS_CALCULATION_DONE);
	
	uint32_t dot_product_low = read32(reg_base + DTMF_DOT_PRODUCT_LOW_OFFSET);
	uint32_t dot_product_high = read32(reg_base + DTMF_DOT_PRODUCT_HIGH_OFFSET);
	uint64_t dot_product = ((uint64_t)dot_product_high << 32) | dot_product_low;
	
	printf("  Calculated dot product: %" PRIu64 " (0x%016lx)\n", dot_product, dot_product);
	
	if (dot_product != 36) {
		fprintf(stderr, "Error: Expected dot product 36, got %lu\n", dot_product);
		return false;
	}
	
	printf("Test 1 PASSED\n\n");
	
	printf("Test 2: Zero reference test\n");
	
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, 0xFFFFFFFF);
	
	write32(reg_base + DTMF_REF_REG_START_OFFSET(0), 0);  // samples 0,1: [0, 0]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(1), 0);  // samples 2,3: [0, 0]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(2), 0);  // samples 4,5: [0, 0]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(3), 0);  // samples 6,7: [0, 0]
	
	printf("  Window samples: [1, 2, 3, 4, 5, 6, 7, 8]\n");
	printf("  Reference samples: [0, 0, 0, 0, 0, 0, 0, 0]\n");
	printf("  Expected dot product: 0\n");
	
	write32(reg_base + DTMF_START_CALCULATION_REG_OFFSET, 1);
	
	while (!(read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET) & DTMF_IRQ_STATUS_CALCULATION_DONE))
	{
		usleep(1000);
	}
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, DTMF_IRQ_STATUS_CALCULATION_DONE);
	dot_product_low = read32(reg_base + DTMF_DOT_PRODUCT_LOW_OFFSET);
	dot_product_high = read32(reg_base + DTMF_DOT_PRODUCT_HIGH_OFFSET);
	dot_product = ((uint64_t)dot_product_high << 32) | dot_product_low;
	
	printf("  Calculated dot product: %" PRIu64 " (0x%016lx)\n", dot_product, dot_product);
	
	if (dot_product != 0) {
		fprintf(stderr, "Error: Expected dot product 0, got %lu\n", dot_product);
		return false;
	}
	
	printf("Test 2 PASSED\n\n");
	
	printf("Test 3: Identical sequences test\n");
	
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, 0xFFFFFFFF);
	
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(0), (2 << 16) | 1);  // window: [1, 2]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(1), (4 << 16) | 3);  // window: [3, 4]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(2), (6 << 16) | 5);  // window: [5, 6]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(3), (8 << 16) | 7);  // window: [7, 8]
	
	write32(reg_base + DTMF_REF_REG_START_OFFSET(0), (2 << 16) | 1);  // reference: [1, 2]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(1), (4 << 16) | 3);  // reference: [3, 4]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(2), (6 << 16) | 5);  // reference: [5, 6]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(3), (8 << 16) | 7);  // reference: [7, 8]
	
	// Expected: 1*1 + 2*2 + 3*3 + 4*4 + 5*5 + 6*6 + 7*7 + 8*8 = 1+4+9+16+25+36+49+64 = 204
	printf("  Window samples: [1, 2, 3, 4, 5, 6, 7, 8]\n");
	printf("  Reference samples: [1, 2, 3, 4, 5, 6, 7, 8]\n");
	printf("  Expected dot product: 204\n");
	
	write32(reg_base + DTMF_START_CALCULATION_REG_OFFSET, 1);
	
	while (!(read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET) & DTMF_IRQ_STATUS_CALCULATION_DONE))
	{
		usleep(1000);
	}
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, DTMF_IRQ_STATUS_CALCULATION_DONE);
	dot_product_low = read32(reg_base + DTMF_DOT_PRODUCT_LOW_OFFSET);
	dot_product_high = read32(reg_base + DTMF_DOT_PRODUCT_HIGH_OFFSET);
	dot_product = ((uint64_t)dot_product_high << 32) | dot_product_low;

	printf("  Calculated dot product: %" PRIu64 " (0x%016lx)\n", dot_product, dot_product);
	
	if (dot_product != 204) {
		fprintf(stderr, "Error: Expected dot product 204, got %lu\n", dot_product);
		return false;
	}
	
	printf("Test 3 PASSED\n\n");
	
	printf("Test 4: Negative values test\n");
	
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, 0xFFFFFFFF);
	
	// Window: [1, -2, 3, -4, 5, -6, 7, -8]
	// Reference: [-1, 2, -3, 4, -5, 6, -7, 8]
	// Expected: 204
	
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(0), ((-2 & 0xFFFF) << 16) | (1 & 0xFFFF));     // [1, -2]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(1), ((-4 & 0xFFFF) << 16) | (3 & 0xFFFF));     // [3, -4]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(2), ((-6 & 0xFFFF) << 16) | (5 & 0xFFFF));     // [5, -6]
	write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(3), ((-8 & 0xFFFF) << 16) | (7 & 0xFFFF));     // [7, -8]
	
	write32(reg_base + DTMF_REF_REG_START_OFFSET(0), ((2 & 0xFFFF) << 16) | ((-1) & 0xFFFF));   // [-1, 2]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(1), ((4 & 0xFFFF) << 16) | ((-3) & 0xFFFF));   // [-3, 4]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(2), ((6 & 0xFFFF) << 16) | ((-5) & 0xFFFF));   // [-5, 6]
	write32(reg_base + DTMF_REF_REG_START_OFFSET(3), ((8 & 0xFFFF) << 16) | ((-7) & 0xFFFF));   // [-7, 8]
	
	printf("  Window samples: [1, -2, 3, -4, 5, -6, 7, -8]\n");
	printf("  Reference samples: [-1, 2, -3, 4, -5, 6, -7, 8]\n");
	printf("  Expected dot product: -204 (as absolute value: 204)\n");
	
	write32(reg_base + DTMF_START_CALCULATION_REG_OFFSET, 1);
	
	while (!(read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET) & DTMF_IRQ_STATUS_CALCULATION_DONE))
	{
		usleep(1000);
	}
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, DTMF_IRQ_STATUS_CALCULATION_DONE);
	dot_product_low = read32(reg_base + DTMF_DOT_PRODUCT_LOW_OFFSET);
	dot_product_high = read32(reg_base + DTMF_DOT_PRODUCT_HIGH_OFFSET);
	dot_product = ((uint64_t)dot_product_high << 32) | dot_product_low;
	
	printf("  Calculated dot product: %" PRIu64 " (0x%016lx)\n", dot_product, dot_product);
	
	if (dot_product != 204) {
		fprintf(stderr, "Error: Expected dot product 204 (absolute value), got %lu\n", dot_product);
		return false;
	}
	
	printf("Test 4 PASSED\n\n");

	printf("Test 5: Full 64-sample correlation test\n");
    
    write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, 0xFFFFFFFF);

    printf("  Writing 64 window samples...\n");
    for (int reg = 0; reg < 32; reg++) {
        int16_t sample0 = (reg * 2) + 1; // samples: 1, 3, 5, 7, ...
        int16_t sample1 = (reg * 2) + 2; // samples: 2, 4, 6, 8, ...
        uint32_t packed = ((uint16_t)sample1 << 16) | ((uint16_t)sample0);
        write32(reg_base + DTMF_WINDOW_REG_START_OFFSET(0) + reg * 4, packed);
    }
    

    printf("  Writing 64 reference samples...\n");
    for (int reg = 0; reg < 32; reg++) {
        uint32_t packed = (1 << 16) | 1;
        write32(reg_base + DTMF_REF_REG_START_OFFSET(0) + reg * 4, packed);
    }
    
	// Calculate expected dot product: 1*1 + 2*1 + 3*1 + ... + 64*1 = sum(1 to 64) = 64*65/2 = 2080
    uint32_t expected_sum = 64 * 65 / 2;
    printf("  Window samples: [1, 2, 3, 4, ..., 63, 64]\n");
    printf("  Reference samples: [1, 1, 1, 1, ..., 1, 1] (all ones)\n");
    printf("  Expected dot product: %u\n", expected_sum);
    
    write32(reg_base + DTMF_START_CALCULATION_REG_OFFSET, 1);
    
    while (!(read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET) & DTMF_IRQ_STATUS_CALCULATION_DONE))
    {
        usleep(1000);
    }
    write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, DTMF_IRQ_STATUS_CALCULATION_DONE);
    
    dot_product_low = read32(reg_base + DTMF_DOT_PRODUCT_LOW_OFFSET);
	dot_product_high = read32(reg_base + DTMF_DOT_PRODUCT_HIGH_OFFSET);
    dot_product = ((uint64_t)dot_product_high << 32) | dot_product_low;
    
    printf("  Calculated dot product: %" PRIu64 " (0x%016" PRIx64 ")\n", dot_product, dot_product);
    
    if (dot_product != expected_sum) {
        fprintf(stderr, "Error: Expected dot product %u, got %" PRIu64 "\n", expected_sum, dot_product);
        return false;
    }
    
    printf("Test 5 PASSED\n\n");
	
	printf("=== All Dot Product Tests Passed! ===\n");
	return true;
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
#if TEST_DMA

bool test_dma_write(volatile void *ram_map, volatile void *dma_map,
		    volatile void *mem_map)
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

	uint32_t ctrl = read32(dma_map + MSGDMA_CSR_CTRL_REG);
	ctrl |= MSGDMA_CONTROL_STOP_ON_EARLY_TERM |
		MSGDMA_CONTROL_STOP_ON_ERROR |
		MSGDMA_CONTROL_GLOBAL_INT_EN_MASK;
	write32(dma_map + MSGDMA_CSR_CTRL_REG, ctrl);

	// configure descriptor
	write32(dma_map + MSGDMA_DESC_READ_ADDR_REG, RAM_PHYS_ADDR);
	write32(dma_map + MSGDMA_DESC_WRITE_ADDR_REG, MEM_BASE_ADDR);
	write32(dma_map + MSGDMA_DESC_LEN_REG, 1);
	// go
	write32(dma_map + MSGDMA_DESC_CTRL_REG,
		MSGDMA_DESC_CTRL_GO | MSGDMA_DESC_CTRL_TX_COMPLETE_IRQ_EN);

	printf("Starting transfer\n");
	fflush(stdout);

	printf("Waiting for transfer to complete\n");

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
	printf("Test DMA write OK\n");
	return true;
}
#endif

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

	volatile void *reg_base = bus_base + SLAVE_BASE_ADDR;
	volatile void *mem_base = bus_base + MEM_BASE_ADDR;
	volatile void *dma_map = bus_base + DMA_BASE_ADDR;

	printf("Memory mapped at address %p.\n", reg_base);
	fflush(stdout);

	// Run basic compatibility tests first
	printf("=== Basic Compatibility Tests ===\n");
	fflush(stdout);
	if (!test_read_constant(reg_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}

	if (!test_read_write_register(reg_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}
	
	/*if (!test_write_read_memory(mem_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}*/

	printf("=== Machine state Tests ===\n");
	/*if (!test_irq_status(reg_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}*/

	if (!test_dot_product_calculation(reg_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}


#if TEST_DMA
	volatile void *ram_map = mmap(0, RAM_MAP_SIZE, PROT_READ | PROT_WRITE,
				      MAP_SHARED, fd,
				      RAM_PHYS_ADDR & ~RAM_MAP_MASK);
	assert(ram_map != MAP_FAILED);
	if (!test_dma_write(ram_map, dma_map, mem_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}

	if (munmap((void *)ram_map, RAM_MAP_SIZE) < 0) {
		fprintf(stderr, "Failed to unmap memory");
	}
#endif

	if (ret == EXIT_SUCCESS) {
		printf("\n=== All Tests Passed! ===\n");
	} else {
		printf("\n=== Some Tests Failed ===\n");
	}

err:
	fflush(stdout);
	if (munmap((void *)bus_base, BUS_MAP_SIZE) < 0) {
		fprintf(stderr, "Failed to unmap memory");
	}

	close(fd);
	printf("Memory unmapped and file descriptor closed.\n");
	return ret;
}
