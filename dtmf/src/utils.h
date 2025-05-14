
#ifndef UTILS_H
#define UTILS_H
#include <stddef.h>
#include <stdbool.h>

#define ARRAY_LEN(arr) (sizeof(arr) / sizeof(arr[0]))

size_t align_to_power_of_2(size_t n);
bool is_power_of_2(size_t n);

#endif
