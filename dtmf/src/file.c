
#include <stdio.h>
#include <stdlib.h>

char *file_read(const char *file)
{
	FILE *fp = fopen(file, "rt");
	if (!fp) {
		printf("Failed to open %s\n", file);
		return NULL;
	}

	fseek(fp, 0, SEEK_END);
	const size_t file_size = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	char *content = (char *)malloc(file_size * sizeof(*content));
	if (!content) {
		printf("Failed to allocate memory for %s\n", file);
		return NULL;
	}

	const size_t read = fread(content, 1, file_size, fp);
	if (read != file_size) {
		printf("Failed to read the whole file %s - Expected: %zu Got %zu\n",
		       file, file_size, read);
		free(content);
		return NULL;
	}

	/* Replace with NULL Terminator */
	if (content[file_size - 1] == '\n') {
		content[file_size - 1] = '\0';
	}

	fclose(fp);
	return content;
}
