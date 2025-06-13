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

static int fpga_set_window_samples(fpga_t *fpga, uint32_t window_samples);

int fpga_init(fpga_t *fpga, uint32_t window_samples)
{
	int fd = open("/dev/de1_io", O_RDWR);
	if (fd < 0) {
		return fd;
	}
	printf("Opened FPGA device file\n");
	fpga->fd = fd;

	int ret = ioctl(fpga->fd, IOCTL_RESET_DEVICE);
	if (ret) {
		printf("Failed to reset device %d\n", ret);
	}
	ret = fpga_set_window_samples(fpga, window_samples);
	if (ret) {
		printf("Failed to set window size (%d). Is it too big (%d)?\n",
		       ret, window_samples);
	}
	fpga->window_samples = window_samples;
	return ret;
}

static int fpga_set_window_samples(fpga_t *fpga, uint32_t window_samples)
{
	return ioctl(fpga->fd, IOCTL_SET_WINDOW_SAMPLES, window_samples);
}

int fpga_calculate_windows(fpga_t *fpga, buffer_t *windows_buffer,
			   int16_t *signal, int16_t *reference_signals,
			   uint8_t nb_buttons)
{
	int err = ioctl(fpga->fd, IOCTL_SET_SIGNAL_ADDR, (long)signal);
	if (err < 0) {
		printf("Failed to set signal addr\n");
		return err;
	}
	err = ioctl(fpga->fd, IOCTL_SET_REF_SIGNAL_ADDR,
		    (long)reference_signals);
	if (err < 0) {
		printf("Failed to set ref signal addr\n");
		return err;
	}

	window_t *windows = windows_buffer->data;
	const size_t len = windows_buffer->len;

	for (size_t i = 0; i < len; ++i) {
		const size_t offset = windows[i].data_offset;
		int ret = ioctl(fpga->fd, IOCTL_SET_WINDOW, offset);
		if (ret) {
			printf("Failed to set window (%d)\n", ret);
			return ret;
		}

		uint64_t best_dot = 0;
		for (size_t j = 0; j < nb_buttons; ++j) {
			const size_t ref_offset = j * fpga->window_samples;

			int ret = ioctl(fpga->fd, IOCTL_SET_REF_WINDOW,
					ref_offset);
			if (ret) {
				printf("Failed to set ref window (%d)\n", ret);
				return ret;
			}

			ret = ioctl(fpga->fd, IOCTL_START_CALCULATION,
				    ref_offset);
			if (ret) {
				printf("Failed to start calculation (%d)\n",
				       ret);
				return ret;
			}

			ssize_t bytes = 0;
			uint64_t dot;
			while (true) {
				bytes = read(fpga->fd, &dot, sizeof(dot));
				if (bytes >= 0) {
					break;
				}
			}

			if (bytes != sizeof(dot)) {
				printf("Failed to get window result %zd\n",
				       bytes);
				return -1;
			}
			if (dot > best_dot) {
				best_dot = dot;
				windows[i].button_index = j;
			}
		}
	}

	return 0;
}

void fpga_terminate(fpga_t *fpga)
{
	close(fpga->fd);
}
