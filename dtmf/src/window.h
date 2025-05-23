#ifndef WINDOW_H
#define WINDOW_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct {
	size_t data_offset;
	uint8_t button_index;
	bool silence_detected_after;
} window_t;

#endif
