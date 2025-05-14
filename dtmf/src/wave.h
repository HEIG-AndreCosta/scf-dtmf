
#ifndef WAVE_H
#define WAVE_H

#include <stddef.h>
#include <stdint.h>

int wave_generate(const char *path, float *buffer, size_t len,
		  uint32_t channels, uint32_t sample_rate);

float *wave_read(const char *path, size_t *len, double *sample_rate);

#endif
