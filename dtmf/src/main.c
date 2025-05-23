#include "buffer.h"
#include "dtmf.h"
#include "file.h"
#include "wave.h"
#include <stdlib.h>
#include <time.h>
#include <stdio.h>
#include <string.h>

typedef char *(*dtmf_decode_fn)(dtmf_t *);
void print_usage(const char *prog)
{
	printf("Usage :\n  %s encode input.txt output.wav\n  %s decode input.wav\n",
	       prog, prog);
}

int decode(const char *wave_file, dtmf_decode_fn decode_fn)
{
	dtmf_t decoder;
	double sample_rate;
	size_t len;
	int32_t *data = wave_read(wave_file, &len, &sample_rate);
	if (!data) {
		return EXIT_FAILURE;
	}

	buffer_construct(&decoder.buffer, data, len, len, sizeof(*data));
	decoder.sample_rate = sample_rate;
	decoder.channels = 1;

	clock_t t;
	t = clock();
	char *value = decode_fn(&decoder);
	t = clock() - t;
	if (!value) {
		printf("Failed to decode\n");
		return EXIT_FAILURE;
	}
	const double time_taken = ((double)t) / CLOCKS_PER_SEC;
	printf("Decoding alone took %g seconds\n", time_taken);

	printf("Decoded: %s\n", value);

	dtmf_terminate(&decoder);
	return EXIT_SUCCESS;
}

int main(int argc, char *argv[])
{
	if (argc < 3) {
		print_usage(argv[0]);
		return 1;
	}

	if (strcmp(argv[1], "encode") == 0) {
		if (argc != 4) {
			print_usage(argv[0]);
			return 1;
		}
		dtmf_t encoder;
		const char *content = file_read(argv[2]);
		if (!content) {
			return EXIT_FAILURE;
		}
		clock_t t;
		t = clock();
		int err = (int)dtmf_encode(&encoder, content) != DTMF_OK;
		t = clock() - t;
		free((void *)content);

		if (err != DTMF_OK) {
			puts(dtmf_err_to_string(err));
			return EXIT_FAILURE;
		}
		const double time_taken = ((double)t) / CLOCKS_PER_SEC;
		printf("Encoding alone took %g seconds\n", time_taken);

		err = wave_generate(argv[3], encoder.buffer.data,
				    encoder.buffer.len, encoder.channels,
				    encoder.sample_rate);
		dtmf_terminate(&encoder);
		return err != 0;

	} else if (strcmp(argv[1], "decode") == 0) {
		return decode(argv[2], dtmf_decode);
	} else if (strcmp(argv[1], "decode_time_domain") == 0) {
		return decode(argv[2], dtmf_decode_time_domain);
	} else {
		print_usage(argv[0]);
		return 1;
	}

	return 0;
}
