
#include "buffer.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
static int reallocate(buffer_t *buffer);

int buffer_init(buffer_t *buffer, size_t capacity, size_t elem_size)
{
	void *ptr = malloc(elem_size * capacity);
	if (!ptr) {
		return -1;
	}
	buffer->capacity = capacity;
	buffer->data = ptr;
	buffer->len = 0;
	buffer->elem_size = elem_size;
	return 0;
}

void buffer_construct(buffer_t *buffer, void *data, size_t capacity, size_t len,
		      size_t elem_size)
{
	buffer->data = data;
	buffer->capacity = capacity;
	buffer->len = len;
	buffer->elem_size = elem_size;
}
int buffer_push(buffer_t *buffer, const void *val)
{
	if (buffer->len >= buffer->capacity) {
		if (reallocate(buffer) < 0) {
			return -1;
		}
	}

	memcpy((uint8_t *)buffer->data + (buffer->len * buffer->elem_size), val,
	       buffer->elem_size);
	buffer->len++;
	return 0;
}
void buffer_terminate(buffer_t *buffer)
{
	free(buffer->data);
	buffer->data = NULL;
	buffer->capacity = 0;
	buffer->len = 0;
	buffer->elem_size = 0;
}

static int reallocate(buffer_t *buffer)
{
	size_t new_capacity = buffer->capacity * 2;
	void *ptr = realloc(buffer->data, new_capacity * buffer->elem_size);
	if (!ptr) {
		return -1;
	}
	buffer->data = ptr;
	buffer->capacity = new_capacity;
	return 0;
}
