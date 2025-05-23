
#ifndef DTMF_H
#define DTMF_H

#include "buffer.h"
#include <stdint.h>
#include <stdbool.h>

#define ENCODE_SAMPLE_RATE 8000

typedef enum {
	DTMF_OK,
	DTMF_INVALID_ENCODING_STRING,
	DTMF_NO_MEMORY,
} dtmf_err_t;

typedef struct {
	buffer_t buffer;
	uint32_t sample_rate;
	uint32_t channels;
} dtmf_t;

bool dtmf_is_valid(const char *value);

dtmf_err_t dtmf_encode(dtmf_t *dtmf, const char *value);
char *dtmf_decode(dtmf_t *dtmf);
char *dtmf_decode_time_domain(dtmf_t *dtmf);
char *dtmf_decode_accelerated(dtmf_t *dtmf);

const char *dtmf_err_to_string(dtmf_err_t err);
void dtmf_terminate(dtmf_t *dtmf);

#endif
