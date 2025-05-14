
#include "utils.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "fft.h"
static void _fft(cplx_t *buf, cplx_t *tmp, size_t n, size_t step);

/*
 * Source: https://rosettacode.org/wiki/Fast_Fourier_transform#C
 */
int fft(cplx_t *buf, size_t n)
{
	if (!is_power_of_2(n)) {
		printf("Can't perform fft if n is not a power of 2\n");
		return 1;
	}

	cplx_t *tmp = (cplx_t *)malloc(n * sizeof(cplx_t));
	if (!tmp) {
		return 1;
	}

	memcpy(tmp, buf, n * sizeof(*buf));
	_fft(buf, tmp, n, 1);
	free(tmp);
	return 0;
}

void float_to_cplx_t(const float *in, cplx_t *out, size_t n)
{
	for (size_t i = 0; i < n; ++i) {
		out[i] = in[i] + 0. * I;
	}
}
void extract_frequencies(const cplx_t *buf, size_t n, double sample_rate,
			 uint32_t *f1, uint32_t *f2)
{
	const size_t half = n / 2;
	double mag_f1 = 0;
	double mag_f2 = 0;

	for (size_t i = 0; i < half; ++i) {
		const double magnitude = cabs(buf[i]) / n;
		const double frequency = (i * sample_rate) / n;
		if (magnitude > mag_f1) {
			mag_f2 = mag_f1;
			mag_f1 = magnitude;
			*f2 = *f1;
			*f1 = frequency;
		} else if (magnitude > mag_f2) {
			mag_f2 = magnitude;
			*f2 = frequency;
		}
	}
}

/*
 * Source: https://rosettacode.org/wiki/Fast_Fourier_transform#C
 */
static void _fft(cplx_t *buf, cplx_t *tmp, size_t n, size_t step)
{
	if (n < 2) {
		return;
	}
	const size_t half = n / 2;

	for (size_t i = 0; i < half; ++i) {
		tmp[i] = buf[2 * i];
		tmp[i + half] = buf[2 * i + 1];
	}

	_fft(tmp, buf, half, step * 2);
	_fft(tmp + half, buf + half, half, step * 2);

	for (size_t i = 0; i < half; ++i) {
		const cplx_t t = cexp(-2.0 * I * M_PI * i / n) * tmp[i + half];
		buf[i] = tmp[i] + t;
		buf[i + half] = tmp[i] - t;
	}
}
