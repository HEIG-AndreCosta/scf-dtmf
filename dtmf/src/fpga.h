
#ifndef FPGA_H
#define FPGA_H

#include "buffer.h"
#include <stddef.h>
#include <stdint.h>
#include <unistd.h>
typedef struct {
	int fd;
	uint32_t window_size;
} fpga_t;

int fpga_init(fpga_t *fpga, uint32_t window_size);
ssize_t fpga_set_reference_signals(fpga_t *fpga, int16_t *reference_signals,
				   size_t len);
int fpga_calculate_windows(fpga_t *fpga, buffer_t *windows, int16_t *signal);
void fpga_terminate(fpga_t *fpga);

#endif
