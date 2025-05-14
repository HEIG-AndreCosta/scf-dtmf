#include <stdio.h>
#include <stdlib.h>
#include <sndfile.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input.wav> <output.wav>\n", argv[0]);
        return 1;
    }

    const char *input_filename = argv[1];
    const char *output_filename = argv[2];

    SF_INFO sfinfo;
    SNDFILE *infile = sf_open(input_filename, SFM_READ, &sfinfo);
    if (!infile) {
        fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier '%s': %s\n", input_filename, sf_strerror(NULL));
        return 1;
    }

    SF_FORMAT_INFO	format_info ;
    format_info.format = sfinfo.format ;
    sf_command (infile, SFC_GET_FORMAT_INFO, &format_info, sizeof (format_info)) ;

    printf("Informations sur le fichier '%s':\n", input_filename);
    printf("  - Format : %08x  %s %s\n", format_info.format, format_info.name, format_info.extension);
    printf("  - Nombre de canaux : %d\n", sfinfo.channels);
    printf("  - Fréquence d'échantillonnage : %d Hz\n", sfinfo.samplerate);
    printf("  - Nombre d'échantillons : %lld\n", (long long)sfinfo.frames);
    printf("  - Durée : %.2f secondes\n", (double)sfinfo.frames / sfinfo.samplerate);

    if ((sfinfo.format & SF_FORMAT_TYPEMASK) != SF_FORMAT_WAV) {
        fprintf(stderr, "Erreur: Le fichier n'est pas au format WAV.\n");
        sf_close(infile);
        return 1;
    }

    float *buffer = (float *)malloc(sfinfo.frames * sfinfo.channels * sizeof(float));
    if (!buffer) {
        fprintf(stderr, "Erreur: Impossible d'allouer de la mémoire.\n");
        sf_close(infile);
        return 1;
    }

    sf_count_t frames_read = sf_readf_float(infile, buffer, sfinfo.frames);
    if (frames_read != sfinfo.frames) {
        fprintf(stderr, "Avertissement: Seuls %lld frames sur %lld ont été lus.\n",
                (long long)frames_read, (long long)sfinfo.frames);
    }

    sf_close(infile);

    SNDFILE *outfile = sf_open(output_filename, SFM_WRITE, &sfinfo);
    if (!outfile) {
        fprintf(stderr, "Erreur: Impossible de créer le fichier '%s': %s\n", output_filename, sf_strerror(NULL));
        free(buffer);
        return 1;
    }

    sf_writef_float(outfile, buffer, frames_read);

    sf_close(outfile);
    free(buffer);

    printf("Fichier '%s' traité et écrit dans '%s'.\n", input_filename, output_filename);
    return 0;
}