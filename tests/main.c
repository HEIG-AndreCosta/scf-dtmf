#include <assert.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

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
#define MEM_SIZE		 0x2000

// DTMF Correlation Test Constants (matching driver and VHDL)
#define DTMF_MEM_BASE			       		0x2000
#define DTMF_WINDOW_START_ADDR		       DTMF_MEM_BASE
#define WINDOW_REGION_SIZE                     4096
#define WINDOW_REGION_SIZE_IN_ADDRESS          1024
#define REF_SIGNALS_REGION_SIZE                2048
#define DTMF_REF_SIGNAL_START_ADDR	       (DTMF_WINDOW_START_ADDR + WINDOW_REGION_SIZE)

// DTMF Register Offsets (matching correlation.vhd)
#define DTMF_ID_REG_OFFSET		       			0x00
#define DTMF_TEST_REG_OFFSET		       		0x04
#define DTMF_START_CALCULATION_REG_OFFSET      	0x08
#define DTMF_WINDOW_SIZE_REG_OFFSET	       		0x0C
#define DTMF_WINDOW_NUMBER_REG_OFFSET	       	0x08
#define DTMF_IRQ_STATUS_REG_OFFSET	       		0x10
#define DTMF_LAST_MEM_RD_ADDR_REG_OFFSET       	0x14
#define DTMF_LAST_MEM_RD_BYTEENABLE_REG_OFFSET 	0x18
#define DTMF_LAST_MEM_RD_COUNT_REG_OFFSET      	0x1C
#define DTMF_LAST_MEM_WR_ADDR_REG_OFFSET       	0x20
#define DTMF_LAST_MEM_WR_BYTEENABLE_REG_OFFSET 	0x24
#define DTMF_LAST_MEM_WR_COUNT_REG_OFFSET      	0x28
#define CORRELATION_STATE_OFFSET				0X2C

// Result registers (starting at 0x100)
#define DTMF_WINDOW_RESULT_REG_0_7             0x100
#define DTMF_WINDOW_RESULT_REG_8_15            0x104
#define DTMF_WINDOW_RESULT_REG_16_23           0x108
#define DTMF_WINDOW_RESULT_REG_24_31           0x10C
#define DTMF_WINDOW_RESULT_REG_32_34           0x110

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
		if (status & DTMF_IRQ_STATUS_CALCULATION_DONE) {
			fprintf(stderr,
				"Error: IRQ status still not reset. Status %#08x\n",
				status);
			return false;
		}
	}

	write32(reg_base + DTMF_WINDOW_SIZE_REG_OFFSET, DEFAULT_WINDOW_SIZE *
						       BYTES_PER_SAMPLE);
	uint32_t window_size = read32(reg_base + DTMF_WINDOW_SIZE_REG_OFFSET);
	if (window_size != DEFAULT_WINDOW_SIZE * BYTES_PER_SAMPLE) {
		fprintf(stderr,
			"Error: Window size not set correctly. Expected %u but got %u\n",
			DEFAULT_WINDOW_SIZE * BYTES_PER_SAMPLE, window_size);
		return false;
	}
	write32(reg_base + DTMF_WINDOW_NUMBER_REG_OFFSET, 5);
	uint32_t window_number = read32(reg_base + DTMF_WINDOW_NUMBER_REG_OFFSET);
	if (window_number != 5) {
		fprintf(stderr,
			"Error: Window number not set correctly. Expected %u but got %u\n",
			5, window_number);
		return false;
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
	write32(reg_base + DTMF_START_CALCULATION_REG_OFFSET, 0x2);
	printf("Waiting for machine to reset\n");
	fflush(stdout);

	while (read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET) &
	       DTMF_IRQ_STATUS_CALCULATION_DONE)
		;

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

// Test that setup real value for correlation works, so need ref values and windows value that can be correlated
bool testing_real_value_for_correlation(volatile void *reg_base, volatile void *mem_base)
{
	printf("Testing real value for correlation\n");

	uint32_t num_windows = 3;
	uint32_t window_size_samples = 8; // must be even apparently

	
	// Setup the state machine

	// clear irq status
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET, 0xFFFFFFFF);
	uint32_t status = read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET);
	if (status & DTMF_IRQ_STATUS_CALCULATION_DONE) {
		fprintf(stderr,
			"Error: Machine did not reset correctly. Status %#08x\n",
			status);
		return false;
	}

	// Set the window size
	write32(reg_base + DTMF_WINDOW_SIZE_REG_OFFSET, window_size_samples);
	uint32_t window_size = read32(reg_base + DTMF_WINDOW_SIZE_REG_OFFSET);
	if (window_size != window_size_samples) {
		fprintf(stderr,
			"Error: Window size not set correctly. Expected %u but got %u\n",
			DEFAULT_WINDOW_SIZE, window_size);
		return false;
	}

	// Create simple reference signals (just patterns like 1,2,3,4... for each reference)
    uint32_t *ref_base = (uint32_t *)(mem_base + DTMF_REF_SIGNAL_START_ADDR);
    for (int ref = 0; ref < NUM_DTMF_BUTTONS; ref++) {
        for (int i = 0; i < window_size_samples; i += 2) {
            int16_t sample0 = (ref + 1) * 100 + i;
            int16_t sample1 = (ref + 1) * 100 + i + 1;
            uint32_t packed = ((uint16_t)sample0) | (((uint16_t)sample1) << 16);
            ref_base[ref * (window_size_samples / 2) + (i / 2)] = packed;
        }
        printf("  Reference %d: pattern starting with %d\n", ref, (ref + 1) * 100);
    }
	// Ensure the reference signals are correctly set in memory
	for (int ref = 0; ref < NUM_DTMF_BUTTONS; ref++) {
		for (int i = 0; i < window_size_samples / 2; i++) {
			uint32_t expected_value = ref_base[ref * (window_size_samples / 2) + i];
			uint32_t actual_value = read32(mem_base + DTMF_REF_SIGNAL_START_ADDR + ref * (window_size_samples / 2) * 4 + i * 4);
			if (actual_value != expected_value) {
				fprintf(stderr,
					"Error: Reference %d sample %d expected %08x but got %08x\n",
					ref, i, expected_value, actual_value);
				return false;
			}
		}
	}

	// Create simple window data that should correlate with specific references
    uint32_t *window_base = (uint32_t *)(mem_base + DTMF_WINDOW_START_ADDR);
    int expected_matches[] = {2, 5, 8};  // Window 0 should match ref 2, etc.

    for (int w = 0; w < num_windows; w++) {
        int target_ref = expected_matches[w];
        for (int i = 0; i < window_size_samples; i += 2) {
            int16_t sample0 = (target_ref + 1) * 100 + i;
            int16_t sample1 = (target_ref + 1) * 100 + i + 1;
            uint32_t packed = ((uint16_t)sample0) | (((uint16_t)sample1) << 16);
            window_base[w * (window_size_samples / 2) + (i / 2)] = packed;
        }
        printf("  Window %d: copying reference %d pattern\n", w, target_ref);
    }
	// Ensure the window data is correctly set in memory
	for (int w = 0; w < num_windows; w++) {
		for (int i = 0; i < window_size_samples / 2; i++) {
			uint32_t expected_value = window_base[w * (window_size_samples / 2) + i];
			uint32_t actual_value = read32(mem_base + DTMF_WINDOW_START_ADDR + w * (window_size_samples / 2) * 4 + i * 4);
			if (actual_value != expected_value) {
				fprintf(stderr,
					"Error: Window %d sample %d expected %08x but got %08x\n",
					w, i, expected_value, actual_value);
				return false;
			}
		}
	}

	printf("Reference memory dump:\n");
	for (int i = 0; i < 4; ++i) {
	    printf("ref_base[%d] = 0x%08x\n", i, ref_base[i]);
	}
	printf("Window memory dump:\n");
	for (int i = 0; i < 4; ++i) {
	    printf("window_base[%d] = 0x%08x\n", i, window_base[i]);
	}

	// Start the calculation
	write32(reg_base + DTMF_START_CALCULATION_REG_OFFSET, 0x3);
	printf("Waiting for machine to reset\n");
	fflush(stdout);
	uint32_t state;
	while (read32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET) & DTMF_IRQ_STATUS_CALCULATION_DONE){
			state = read32(reg_base + CORRELATION_STATE_OFFSET);
			printf("State: %#08x\n", state);
		   }
	// Acknowledge the irq
	write32(reg_base + DTMF_IRQ_STATUS_REG_OFFSET,
		DTMF_IRQ_STATUS_CALCULATION_DONE);


    // Check results
    bool all_correct = true;
	uint32_t result = read32(reg_base + DTMF_WINDOW_RESULT_REG_0_7);
    for (int w = 0; w < num_windows; w++) {
        int bit_offset = w * 4;
		uint32_t detected_ref = (result >> bit_offset) & 0x0F;
        uint32_t expected_ref = expected_matches[w];
        
        printf("  Window %d: Expected ref %d, Got ref %d %s\n", 
               w, expected_ref, detected_ref, 
               (detected_ref == expected_ref) ? "✓" : "✗");
        
        if (detected_ref != expected_ref) {
            all_correct = false;
        }
    }

    printf("Simple correlation test: %s\n", all_correct ? "PASSED" : "FAILED");
	return all_correct;
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

	// Run basic compatibility tests first
	printf("=== Basic Compatibility Tests ===\n");
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

	printf("=== Machine state Tests ===\n");
	/*if (!test_irq_status(reg_base)) {
		ret = EXIT_FAILURE;
		goto err;
	}*/

	if (!testing_real_value_for_correlation(reg_base, mem_base)) {
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
