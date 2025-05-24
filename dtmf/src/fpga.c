
#include "access.h"
#include "fpga.h"
#include "window.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

static int fpga_set_window_size(fpga_t *fpga);

int fpga_init(fpga_t *fpga, uint32_t window_size)
{
	int fd = open("/dev/de1io", O_RDWR);
	if (fd < 0) {
		return fd;
	}

	fpga->fd = fd;
	fpga->window_nsamples = window_size;

	fpga_set_window_size(fpga);
	return 0;
}

static int fpga_set_window_size(fpga_t *fpga)
{
	int err = ioctl(fpga->fd, IOCTL_SET_MODE, IOCTL_MODE_SET_WINDOW_SIZE);
	if (err < 0) {
		return err;
	}
	return (int)write(fpga->fd, &fpga->window_nsamples,
			  sizeof(fpga->window_nsamples));
}
ssize_t fpga_set_reference_signals(fpga_t *fpga, int16_t *reference_signals,
				   size_t len)
{
	int err = ioctl(fpga->fd, IOCTL_SET_MODE,
			IOCTL_MODE_SET_REFERENCE_SIGNALS);
	if (err < 0) {
		return err;
	}

	return (int)write(fpga->fd, reference_signals, len);
}

int fpga_set_windows(fpga_t *fpga, buffer_t *windows_buffer, int16_t *signal)
{
	const window_t *windows = windows_buffer->data;
	const size_t len = windows_buffer->len;

	int err = ioctl(fpga->fd, IOCTL_SET_MODE, IOCTL_MODE_SET_WINDOWS);
	if (err < 0) {
		return err;
	}

	for (size_t i = 0; i < len; ++i) {
		size_t offset = windows[i].data_offset;
		ssize_t ret =
			write(fpga->fd, &signal[offset], fpga->window_nsamples);
		if (ret < 0) {
			return (int)ret;
		}
	}
	return 0;
}

int fpga_calculate(fpga_t *fpga, buffer_t *windows_buffer)
{
	window_t *windows = windows_buffer->data;
	const size_t len = windows_buffer->len;
	const size_t expected_bytes = len;
	uint8_t *btn_indexes = (uint8_t *)malloc(expected_bytes);

	ssize_t ret = read(fpga->fd, btn_indexes, expected_bytes);
	if (ret < 0) {
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
