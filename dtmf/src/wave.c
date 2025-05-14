
#include "wave.h"
#include <sndfile-64.h>
#include <stdlib.h>

int wave_generate(const char *path, float *buffer, size_t len,
		  uint32_t channels, uint32_t sample_rate)
{
	SF_INFO sfinfo;
	sfinfo.format = SF_FORMAT_WAV | SF_ENDIAN_FILE | SF_FORMAT_FLOAT;
	sfinfo.frames = len;
	sfinfo.channels = channels;
	sfinfo.samplerate = sample_rate;

	SNDFILE *outfile = sf_open(path, SFM_WRITE, &sfinfo);
	if (!outfile) {
		printf("Error creating wave file: %s\n", sf_strerror(NULL));
		return -1;
	}

	sf_writef_float(outfile, buffer, len);
	sf_close(outfile);
	return 0;
}

float *wave_read(const char *path, size_t *len, double *sample_rate)
{
	SF_INFO sfinfo;
	SNDFILE *infile = sf_open(path, SFM_READ, &sfinfo);
	if (!infile) {
		printf("Error opening wave file (%s): %s\n", path,
		       sf_strerror(NULL));
		return NULL;
	}

	SF_FORMAT_INFO format_info;
	format_info.format = sfinfo.format;
	sf_command(infile, SFC_GET_FORMAT_INFO, &format_info,
		   sizeof(format_info));

#if 0
	printf("Informations sur le fichier '%s':\n", path);
	printf("  - Format : %08x  %s %s\n", format_info.format,
	       format_info.name, format_info.extension);
	printf("  - Nombre de canaux : %d\n", sfinfo.channels);
	printf("  - Fréquence d'échantillonnage : %d Hz\n", sfinfo.samplerate);
	printf("  - Nombre d'échantillons : %lld\n", (long long)sfinfo.frames);
	printf("  - Durée : %.2f secondes\n",
	       (double)sfinfo.frames / sfinfo.samplerate);
#endif

	*len = sfinfo.frames;
	*sample_rate = sfinfo.samplerate;

	if ((sfinfo.format & SF_FORMAT_TYPEMASK) != SF_FORMAT_WAV) {
		printf("Error. The file (%s) is not in wave format\n", path);
		sf_close(infile);
		return NULL;
	}

	float *buffer = (float *)malloc(sfinfo.frames * sfinfo.channels *
					sizeof(float));
	if (!buffer) {
		fprintf(stderr, "Error allocating memory\n");
		sf_close(infile);
		return NULL;
	}

	sf_count_t frames_read = sf_readf_float(infile, buffer, sfinfo.frames);
	if (frames_read != sfinfo.frames) {
		fprintf(stderr,
			"Avertissement: Seuls %lld frames sur %lld ont été lus.\n",
			(long long)frames_read, (long long)sfinfo.frames);
	}

	sf_close(infile);
	return buffer;
}
