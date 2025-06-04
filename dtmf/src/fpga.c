
#include "access.h"
#include "fpga.h"
#include "window.h"
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

static int fpga_set_window_size(fpga_t *fpga);
static int fpga_calculate(fpga_t *fpga, window_t *windows, size_t len);

int fpga_init(fpga_t *fpga, uint32_t window_size)
{
	int fd = open("/dev/de1_io", O_RDWR);
	if (fd < 0) {
		return fd;
	}
	printf("Opened FPGA device file\n");
	if (window_size > WINDOW_REGION_SIZE) {
		printf("Requested window size > total WINDOW_REGION_SIZE (%u > %u)",
		       window_size, WINDOW_REGION_SIZE);
		return -1;
	}

	fpga->fd = fd;
	fpga->window_size = window_size;

	printf("set window size\n");
	fpga_set_window_size(fpga);
	printf("set window size finished\n");
	return 0;
}

static int fpga_set_window_size(fpga_t *fpga)
{
	return ioctl(fpga->fd, IOCTL_SET_WINDOW_SIZE, fpga->window_size);
}
ssize_t fpga_set_reference_signals(fpga_t *fpga, int16_t *reference_signals,
				   size_t len)
{
	return write(fpga->fd, reference_signals, len);
}

int fpga_calculate_windows(fpga_t *fpga, buffer_t *windows_buffer,
			   int16_t *signal)
{
	int err = ioctl(fpga->fd, IOCTL_SET_SIGNAL_ADDR, (long)signal);
	if (err < 0) {
		printf("Failed to set correct driver mode\n");
		return err;
	}

	window_t *windows = windows_buffer->data;
	const size_t len = windows_buffer->len;
	size_t current_count = 0;
	size_t current_start_index = 0;

	printf("DEBUG: Processing %zu windows\n", len);

	for (size_t i = 0; i < len; ++i) {
		current_count += fpga->window_size;
		const size_t offset = windows[i].data_offset;
		printf("DEBUG: Window %zu, offset: %zu, current_count: %zu\n", i, offset, current_count);
		if (current_count > WINDOW_REGION_SIZE) {
			/* Can't transfer the next chunk as we will exceed the region size
			 * So trigger a calculation for the already sent windows
			 */
			printf("DEBUG: Triggering calculation for batch (windows %zu to %zu)\n", current_start_index, i-1); 
			int ret = fpga_calculate(fpga,
						 windows + current_start_index,
						 current_count);
			if (ret < 0) {
				printf("Failed to get window results\n");
				return ret;
			}
			current_count = 0;
			current_start_index = i;
		}

		int ret = ioctl(fpga->fd, IOCTL_SET_WINDOW, offset);
		if (ret) {
			printf("Failed to send windows. ioctl returned: %d, errno: %d (%s)\n", 
           ret, errno, strerror(errno));
			return ret;
		}
	}

	printf("DEBUG: All windows processed successfully\n");

	return 0;
}

static int fpga_calculate(fpga_t *fpga, window_t *windows, size_t len)
{
	const size_t expected_bytes = len;
	uint8_t *btn_indexes = (uint8_t *)malloc(expected_bytes);
	if (!btn_indexes) {
		printf("Failed to allocate memory for calculation result\n");
		return -1;
	}

	ssize_t ret = read(fpga->fd, btn_indexes, expected_bytes);
	if (ret < 0) {
		printf("Failed to read result\n");
		return (int)ret;
	}

	/* Safe cast as per check above */
	size_t bytes_read = (size_t)ret;
	if (bytes_read < len * sizeof(*btn_indexes)) {
		printf("Expected %zu bytes but only got %zu", expected_bytes,
		       bytes_read);
		return -1;
	}
	for (size_t i = 0; i < len; ++i) {
		windows[i].button_index = btn_indexes[i];
	}
	return 0;
}
void fpga_terminate(fpga_t *fpga)
{
	close(fpga->fd);
}
