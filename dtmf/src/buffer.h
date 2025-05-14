
#ifndef BUFFER_H
#define BUFFER_H

#include <stddef.h>

typedef struct {
	void *data;
	size_t capacity; /* In number of elements */
	size_t len; /* Number of valid elements */
	size_t elem_size; /* Size of each element */
} buffer_t;

int buffer_init(buffer_t *buffer, size_t capacity, size_t elem_size);
void buffer_construct(buffer_t *buffer, void *data, size_t capacity, size_t len,
		      size_t elem_size);
int buffer_push(buffer_t *buffer, const void *val);
void buffer_terminate(buffer_t *buffer);

#endif
