
#ifndef FPGA_H
#define FPGA_H

#include "buffer.h"
#include <stddef.h>
#include <stdint.h>
#include <unistd.h>
typedef struct {
	int fd;
	uint32_t window_samples;
} fpga_t;

int fpga_init(fpga_t *fpga, uint32_t window_size);
int fpga_calculate_windows(fpga_t *fpga, buffer_t *windows_buffer,
			   int16_t *signal, int16_t *reference_signals,
			   uint8_t nb_buttons);
void fpga_terminate(fpga_t *fpga);

#endif
