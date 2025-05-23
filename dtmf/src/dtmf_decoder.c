#include "dtmf.h"
#include "dtmf_private.h"

#include "buffer.h"
#include "fpga.h"
#include "utils.h"
#include "fft.h"
#include "window.h"
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#define RESULT_BUFFER_INITIAL_LEN 128
#define MIN_FREQ		  650
#define MAX_FREQ		  1500

typedef dtmf_button_t *(*dtmf_decode_button_cb_t)(const int16_t *signal,
						  cplx_t *buffer, size_t len,
						  uint32_t sample_rate);

static dtmf_button_t *decode_button_frequency_domain(const int16_t *signal,
						     cplx_t *buffer, size_t len,
						     uint32_t sample_rate);

static dtmf_button_t *decode_button_time_domain(const int16_t *signal,
						cplx_t *buffer, size_t len,
						uint32_t sample_rate);

/* Used for time domain decoding in order to correlate */
static int16_t *button_reference_signals = NULL;
static bool generated_references = false;

static void generate_reference_signals(size_t len, uint32_t sample_rate);
static const uint16_t ROW_FREQUENCIES[] = { 697, 770, 852, 941 };
static const uint16_t COL_FREQUENCIES[] = { 1209, 1336, 1477 };

#define NB_BUTTONS ARRAY_LEN(ROW_FREQUENCIES) * ARRAY_LEN(COL_FREQUENCIES)

static int16_t get_max_amplitude(const int16_t *buffer, size_t len);
static bool is_silence(const int16_t *buffer, size_t len, int16_t target);
static bool is_valid_frequency(uint32_t freq);
static int push_decoded(dtmf_button_t *btn, buffer_t *result, size_t *presses);
static ssize_t find_start_of_file(dtmf_t *dtmf, cplx_t *buffer, size_t len,
				  int16_t *amplitude);

static char *dtmf_decode_internal(dtmf_t *dtmf,
				  dtmf_decode_button_cb_t decode_button_fn);

static char *dtmf_decode_internal_accelerated(dtmf_t *dtmf);

static inline size_t decode_samples_to_skip_on_silence(uint32_t sample_rate)
{
	return CHAR_PAUSE_SAMPLES(sample_rate) -
	       SAME_CHAR_PAUSE_SAMPLES(sample_rate);
}
static inline size_t decode_samples_to_skip_on_press(uint32_t sample_rate)
{
	return CHAR_SOUND_SAMPLES(sample_rate) +
	       SAME_CHAR_PAUSE_SAMPLES(sample_rate);
}

const char *dtmf_err_to_string(dtmf_err_t err)
{
	switch (err) {
	case DTMF_OK:
		return "dtmf ok";
	case DTMF_INVALID_ENCODING_STRING:
		return "dtmf invalid encoding string";
	case DTMF_NO_MEMORY:
		return "dtmf no memory";
	}
	return "dtmf unknown error";
}

char *dtmf_decode_time_domain(dtmf_t *dtmf)
{
	return dtmf_decode_internal(dtmf, decode_button_time_domain);
}

char *dtmf_decode(dtmf_t *dtmf)
{
	return dtmf_decode_internal(dtmf, decode_button_frequency_domain);
}

char *dtmf_decode_accelerated(dtmf_t *dtmf)
{
	return dtmf_decode_internal_accelerated(dtmf);
}

static char *dtmf_decode_internal_accelerated(dtmf_t *dtmf)
{
	const size_t samples_to_skip_on_silence =
		decode_samples_to_skip_on_silence(dtmf->sample_rate);
	const size_t samples_to_skip_on_press =
		decode_samples_to_skip_on_press(dtmf->sample_rate);
	const size_t min_len = SAME_CHAR_PAUSE_SAMPLES(dtmf->sample_rate);

	const size_t len =
		is_power_of_2(min_len) ? min_len : align_to_power_of_2(min_len);

	int16_t target_amplitude = 0;
	ssize_t start = 0;
	{
		cplx_t *buffer = calloc(len, sizeof(*buffer));
		if (!buffer) {
			printf("Failed to allocate memory for decode\n");
			return NULL;
		}

		start = find_start_of_file(dtmf, buffer, len,
					   &target_amplitude);
		free(buffer);
	}

	if (start < 0) {
		printf("Couldn't find the first button press\n");
		return NULL;
	}
	if (start > 0) {
		printf("Couldn't find a button press at the start of the file.\n");
		return NULL;
	}

	size_t i = (size_t)start;
	const size_t window_size = 5 * (dtmf->sample_rate / ROW_FREQUENCIES[0]);

	/* Windows */
	buffer_t windows;
	int ret = buffer_init(&windows, RESULT_BUFFER_INITIAL_LEN,
			      sizeof(window_t));
	if (ret < 0) {
		printf("Failed to allocate memory for decode result\n");
		return NULL;
	}

	/* FPGA */
	fpga_t fpga;
	ret = fpga_init(&fpga, window_size);
	if (ret < 0) {
		buffer_terminate(&windows);
		printf("Failed to connect to FPGA\n");
		return NULL;
	}

	/* Reference signals  */
	generate_reference_signals(window_size, dtmf->sample_rate);
	fpga_set_reference_signals(&fpga, button_reference_signals,
				   window_size * NB_BUTTONS *
					   sizeof(*button_reference_signals));

	/* Generate windows*/
	while ((i + len) < dtmf->buffer.len) {
		/* First check for silence */
		if (is_silence((int16_t *)dtmf->buffer.data + i, len,
			       target_amplitude)) {
			assert(windows.len != 0);
			window_t *window =
				&((window_t *)windows.data)[windows.len - 1];
			window->silence_detected_after = true;

			i += samples_to_skip_on_silence;
			continue;
		}
		window_t window = { .data_offset = i,
				    .button_index = 0xff,
				    .silence_detected_after = false };

		buffer_push(&windows, &window);
		i += samples_to_skip_on_press;
	}

	fpga_set_windows(&fpga, &windows, dtmf->buffer.data);
	fpga_calculate(&fpga, &windows);

	size_t consecutive_presses = 0;
	dtmf_button_t *curr_btn = NULL;
	buffer_t result;
	ret = buffer_init(&result, RESULT_BUFFER_INITIAL_LEN, sizeof(char));
	for (size_t i = 0; i < windows.len; ++i) {
		window_t *window = &((window_t *)windows.data)[i];
		curr_btn = dtmf_get_button_by_index(window->button_index);

		consecutive_presses++;
		if (window->silence_detected_after || i + 1 == windows.len) {
			push_decoded(curr_btn, &result, &consecutive_presses);
		}
	}

	return (char *)result.data;
}

static char *dtmf_decode_internal(dtmf_t *dtmf,
				  dtmf_decode_button_cb_t decode_button_fn)
{
	const size_t samples_to_skip_on_silence =
		decode_samples_to_skip_on_silence(dtmf->sample_rate);
	const size_t samples_to_skip_on_press =
		decode_samples_to_skip_on_press(dtmf->sample_rate);
	const size_t min_len = SAME_CHAR_PAUSE_SAMPLES(dtmf->sample_rate);

	const size_t len =
		is_power_of_2(min_len) ? min_len : align_to_power_of_2(min_len);

	cplx_t *buffer = calloc(len, sizeof(*buffer));
	if (!buffer) {
		printf("Failed to allocate memory for decode\n");
		return NULL;
	}
	buffer_t result;
	int ret = buffer_init(&result, RESULT_BUFFER_INITIAL_LEN, sizeof(char));
	if (ret < 0) {
		printf("Failed to allocate memory for decode result\n");
		free(buffer);
		return NULL;
	}
	int16_t target_amplitude = 0;

	ssize_t start =
		find_start_of_file(dtmf, buffer, len, &target_amplitude);
	if (start < 0) {
		printf("Couldn't find the first button press\n");
		free(buffer);
		buffer_terminate(&result);
		return NULL;
	}

	/* This cast is safe as per the check above*/
	size_t i = (size_t)start;

	dtmf_button_t *btn = NULL;
	size_t consecutive_presses = 0;
	while ((i + len) < dtmf->buffer.len) {
		/* First check for silence */
		if (is_silence((int16_t *)dtmf->buffer.data + i, len,
			       target_amplitude)) {
			/*
			 * btn will never be NULL here since we only get here after
			 * `find_start_of_file` detects the first button press 
			 */
			assert(btn);
			push_decoded(btn, &result, &consecutive_presses);
			i += samples_to_skip_on_silence;
			continue;
		}

		/* No silence here, decode the button */
		dtmf_button_t *new_btn =
			decode_button_fn((int16_t *)dtmf->buffer.data + i,
					 buffer, len, dtmf->sample_rate);

		/* 
		 * Failed to decode the button so this must be noise,
		 * the last button and the number of presses indicates the character to decode
		 */
		if (!new_btn) {
			/* 
			 * If button is still NULL here, it means we weren't able to decode the first 
			 * button press. No point in trying, just fail
			 */
			if (!btn) {
				printf("Failed to decode the first button press... Sorry :(\n");
				free(buffer);
				buffer_terminate(&result);
				return NULL;
			}

			push_decoded(btn, &result, &consecutive_presses);
			/* 
			 * Since we know the pause between button presses takes either SAME_CHAR_PAUSE_DURATION  time
			 * or CHAR_PAUSE_DURATION time, if we get here it means the pause is of CHAR_PAUSE_DURATION time
			 * Simply skip the correct amount of samples and next loop we should detect the next button press
			 */
			i += samples_to_skip_on_silence;
			continue;
		}
		/*
		 * If we get here it either means this is the first time this button is getting pressed
		 * or it's the same button we detected earlier 
		 */
		btn = new_btn;
		consecutive_presses++;
		/* 
		 * Since we know a press must take CHAR_SOUND_DURATION time
		 * and then we will have at least SAME_CHAR_PAUSE_DURATION time
		 * We can simply skip that amount of samples
		 */
		i += samples_to_skip_on_press;
	}

	/* If the file ended without a silence, add the last button */
	if (consecutive_presses != 0) {
		const char decoded =
			dtmf_decode_character(btn, consecutive_presses);
		buffer_push(&result, &decoded);
	}
	const char terminator = '\0';
	buffer_push(&result, &terminator);
	free(buffer);
	return (char *)result.data;
}

void dtmf_terminate(dtmf_t *dtmf)
{
	buffer_terminate(&dtmf->buffer);
}
static ssize_t find_start_of_file(dtmf_t *dtmf, cplx_t *buffer, size_t len,
				  int16_t *amplitude)
{
	assert(is_power_of_2(len));
	uint32_t f1 = 0, f2 = 0;
	size_t i = 0;

	while ((i + len) < dtmf->buffer.len) {
		float_to_cplx_t((int16_t *)dtmf->buffer.data + i, buffer, len);

		int err = fft(buffer, len);
		if (err != 0) {
			printf("Error running fft\n");
			return -1;
		}
		extract_frequencies(buffer, len, dtmf->sample_rate, &f1, &f2);

		if (is_valid_frequency(f1) && is_valid_frequency(f2)) {
			/* Found the start of the file */
			int16_t max_amplitude = get_max_amplitude(
				(int16_t *)dtmf->buffer.data + i, len);

			*amplitude = max_amplitude - (max_amplitude / 10);
			return i;
		} else {
			i += len;
		}
	}
	return i;
}
static int push_decoded(dtmf_button_t *btn, buffer_t *result, size_t *presses)
{
	const char decoded = dtmf_decode_character(btn, *presses);
	*presses = 0;
	return buffer_push(result, &decoded);
}

static int16_t get_max_amplitude(const int16_t *buffer, size_t len)
{
	int16_t amplitude = 0;

	for (size_t i = 0; i < len; ++i) {
		if (buffer[i] > amplitude) {
			amplitude = buffer[i];
		}
	}
	return amplitude;
}

static bool is_silence(const int16_t *buffer, size_t len, int16_t target)
{
	for (size_t i = 0; i < len; ++i) {
		/*printf("buffer[i] >= target %d >= %d\n", buffer[i], target);*/
		if (buffer[i] >= target) {
			return false;
		}
	}
	return true;
}

static bool is_valid_frequency(uint32_t freq)
{
	return freq > MIN_FREQ && freq < MAX_FREQ;
}

uint64_t dot_product_similarity_squared(const int16_t *x, const int16_t *y,
					size_t len)
{
	int64_t dot = 0, norm_x = 0, norm_y = 0;

	for (size_t i = 0; i < len; ++i) {
		int64_t xi = x[i];
		int64_t yi = y[i];

		dot += xi * yi;
		norm_x += xi * xi;
		norm_y += yi * yi;
	}

	if (norm_x == 0 || norm_y == 0)
		return 0;

	int64_t numerator = (int64_t)dot * dot;
	int64_t denom = (int64_t)norm_x * norm_y;
	if (denom == 0) {
		return 0;
	}

	/* Amplify numerator so we don't have 0 all the time */
	return (uint64_t)((numerator << 8) / denom);
}

static dtmf_button_t *decode_button_frequency_domain(const int16_t *signal,
						     cplx_t *buffer, size_t len,
						     uint32_t sample_rate)
{
	uint32_t f1, f2;
	float_to_cplx_t(signal, buffer, len);
	int err = fft(buffer, len);
	if (err != 0) {
		printf("Error running fft\n");
		return NULL;
	}
	extract_frequencies(buffer, len, sample_rate, &f1, &f2);

	if (!(is_valid_frequency(f1) && is_valid_frequency(f2))) {
		return NULL;
	}
	return dtmf_get_closest_button(f1, f2);
}
static void generate_reference_signals(size_t len, uint32_t sample_rate)
{
	button_reference_signals =
		malloc(NB_BUTTONS * len * sizeof(*button_reference_signals));

	for (size_t i = 0; i < ARRAY_LEN(ROW_FREQUENCIES); ++i) {
		for (size_t j = 0; j < ARRAY_LEN(COL_FREQUENCIES); ++j) {
			const size_t window_index =
				(i * ARRAY_LEN(COL_FREQUENCIES) + j) * len;

			for (size_t k = 0; k < len; ++k) {
				button_reference_signals[window_index + k] =
					s(100, ROW_FREQUENCIES[i],
					  COL_FREQUENCIES[j], k, sample_rate);
			}
		}
	}
}

static dtmf_button_t *decode_button_time_domain(const int16_t *signal,
						cplx_t *buffer, size_t len,
						uint32_t sample_rate)
{
	(void)buffer;
	(void)len;
	const size_t nb_samples = 5 * (sample_rate / ROW_FREQUENCIES[0]);
	assert(nb_samples <= len);

	if (!generated_references) {
		generate_reference_signals(nb_samples, sample_rate);
		/* Make sure we only do this once*/
		generated_references = true;
	}

	uint16_t f1 = 0;
	uint16_t f2 = 0;
	uint64_t best_corr = 0;
	for (size_t i = 0; i < ARRAY_LEN(ROW_FREQUENCIES); ++i) {
		const uint16_t row_freq = ROW_FREQUENCIES[i];
		for (size_t j = 0; j < ARRAY_LEN(COL_FREQUENCIES); ++j) {
			const uint16_t col_freq = COL_FREQUENCIES[j];
			const size_t index =
				(i * ARRAY_LEN(COL_FREQUENCIES) + j) *
				nb_samples;
			const uint64_t corr = dot_product_similarity_squared(
				signal, &button_reference_signals[index],
				nb_samples);

			if (corr > best_corr) {
				f1 = row_freq;
				f2 = col_freq;
				best_corr = corr;
			}
		}
	}
	if (!f1 || !f2) {
		return NULL;
	}
	return dtmf_get_closest_button(f1, f2);
}
