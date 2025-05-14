
#ifndef DTMF_PRIVATE_H
#define DTMF_PRIVATE_H
#include "dtmf.h"
#include <stdint.h>

typedef struct {
	size_t index;
	const char *characters;
	uint16_t col_freq;
	uint16_t row_freq;
} dtmf_button_t;

#define CHAR_SOUND_DURATION		0.2
#define CHAR_PAUSE_DURATION		0.2
#define SAME_CHAR_PAUSE_DURATION	0.05

#define CHAR_SOUND_SAMPLES(sample_rate) (CHAR_SOUND_DURATION * (sample_rate))
#define CHAR_PAUSE_SAMPLES(sample_rate) (CHAR_PAUSE_DURATION * (sample_rate))
#define SAME_CHAR_PAUSE_SAMPLES(sample_rate) \
	(SAME_CHAR_PAUSE_DURATION * sample_rate)

dtmf_button_t *dtmf_get_button(char character);
dtmf_button_t *dtmf_get_closest_button(uint16_t f1, uint16_t f2);

size_t dtmf_get_times_to_push(size_t btn_nr, char value, size_t extra_presses);
char dtmf_decode_character(dtmf_button_t *button, size_t presses);

float s(float a, uint32_t f1, uint32_t f2, uint32_t t, uint32_t sample_rate);
#endif
