
#include "dtmf_private.h"

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#define SPECIAL_CHARS ".!?,# "

#define SILENCE_F1    0
#define SILENCE_F2    0
#define EXTRA_PRESSES 0

static bool is_char_valid(char c);
static int encode_internal(buffer_t *buffer, const char *value,
			   uint32_t sample_rate);
static int push_samples(buffer_t *buffer, uint32_t f1, uint32_t f2,
			size_t nb_samples, uint32_t sample_rate);

bool dtmf_is_valid(const char *value)
{
	assert(value);
	for (size_t i = 0; i < strlen(value); ++i) {
		if (!is_char_valid(value[i])) {
			printf("Found invalid character at position %zu (%c)\n",
			       i + 1, value[i]);
			return false;
		}
	}
	return true;
}
dtmf_err_t dtmf_encode(dtmf_t *dtmf, const char *value)
{
	if (!dtmf_is_valid(value)) {
		return DTMF_INVALID_ENCODING_STRING;
	}
	dtmf->channels = 1;
	dtmf->sample_rate = ENCODE_SAMPLE_RATE;

	const size_t initial_capacity =
		strlen(value) * CHAR_SOUND_SAMPLES(dtmf->sample_rate);

	int err = buffer_init(&dtmf->buffer, initial_capacity, sizeof(int16_t));

	if (err < 0) {
		return DTMF_NO_MEMORY;
	}
	return encode_internal(&dtmf->buffer, value, dtmf->sample_rate);
}

static int encode_internal(buffer_t *buffer, const char *value,
			   uint32_t sample_rate)
{
	const size_t nb_samples_on_char_pause = CHAR_PAUSE_SAMPLES(sample_rate);
	const size_t nb_samples_on_same_char_pause =
		SAME_CHAR_PAUSE_SAMPLES(sample_rate);
	const size_t nb_samples_on_char = CHAR_SOUND_SAMPLES(sample_rate);

	for (size_t i = 0; i < strlen(value); ++i) {
		const dtmf_button_t *button = dtmf_get_button(value[i]);
		assert(button);
		const size_t times_to_push = dtmf_get_times_to_push(
			button->index, value[i], EXTRA_PRESSES);

		int err;
		if (i > 0) {
			err = push_samples(buffer, SILENCE_F1, SILENCE_F2,
					   nb_samples_on_char_pause,
					   sample_rate);
			if (err < 0) {
				return DTMF_NO_MEMORY;
			}
		}
		for (size_t j = 0; j < times_to_push; ++j) {
			if (j > 0) {
				err = push_samples(
					buffer, SILENCE_F1, SILENCE_F2,
					nb_samples_on_same_char_pause,
					sample_rate);
				if (err < 0) {
					return DTMF_NO_MEMORY;
				}
			}

			err = push_samples(buffer, button->row_freq,
					   button->col_freq, nb_samples_on_char,
					   sample_rate);
			if (err < 0) {
				return DTMF_NO_MEMORY;
			}
		}
	}
	return DTMF_OK;
}

static int push_samples(buffer_t *buffer, uint32_t f1, uint32_t f2,
			size_t nb_samples, uint32_t sample_rate)
{
	if (f1 != 0) {
		printf("Pushing [%zu,%zu[\n", buffer->len,
		       buffer->len + nb_samples);
	}
	for (size_t i = 0; i < nb_samples; ++i) {
		const int16_t value =
			(int16_t)s(INT16_MAX * 0.4, f1, f2, i, sample_rate);
		int err = buffer_push(buffer, &value);
		if (err < 0) {
			return err;
		}
	}
	return 0;
}

static bool is_char_valid(char c)
{
	return islower(c) || isdigit(c) || strchr(SPECIAL_CHARS, c) != NULL;
}
