#include "access.h"
#include <errno.h>
#include "fpga.h"
#include "window.h"
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

static int fpga_set_window_size(fpga_t *fpga);

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

	int ret = fpga_set_window_size(fpga);
	if (ret != 0) {
		printf("Failed to set window size (%d). Is it too big (%d)?\n",
		       ret, fpga->window_size);
	}
	return ret;
}

static int fpga_set_window_size(fpga_t *fpga)
{
	return ioctl(fpga->fd, IOCTL_SET_WINDOW_SIZE, fpga->window_size);
}

int fpga_calculate_windows(fpga_t *fpga, buffer_t *windows_buffer,
			   int16_t *signal, int16_t *reference_signals)
{
	int err = ioctl(fpga->fd, IOCTL_SET_SIGNAL_ADDR, (long)signal);
	if (err < 0) {
		printf("Failed to set correct driver mode\n");
		return err;
	}
	err = ioctl(fpga->fd, IOCTL_SET_REF_SIGNAL_ADDR,
		    (long)reference_signals);
	if (err < 0) {
		printf("Failed to set correct driver mode\n");
		return err;
	}

	window_t *windows = windows_buffer->data;
	const size_t len = windows_buffer->len;

	for (size_t i = 0; i < len; ++i) {
		const size_t offset = windows[i].data_offset;
		int ret = ioctl(fpga->fd, IOCTL_SET_WINDOW, offset);
		if (ret) {
			printf("Failed to send windows (%d)\n", ret);
			return ret;
		}
		ssize_t bytes = -EAGAIN;
		while (bytes == -EAGAIN) {
			bytes = read(fpga->fd, &windows[i].button_index,
				     sizeof(windows[i].button_index));
		}
		if (bytes != sizeof(windows[i].button_index)) {
			printf("Failed to get window result %zd\n", bytes);
			return -1;
		}
	}

	return 0;
}

void fpga_terminate(fpga_t *fpga)
{
	close(fpga->fd);
}
