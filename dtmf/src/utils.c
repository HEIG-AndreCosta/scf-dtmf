#include "utils.h"

/*
 * Source : https://stackoverflow.com/a/1322548
 */
size_t align_to_power_of_2(size_t n)
{
	--n;
	for (size_t i = 1; i <= 32; i *= 2) {
		n |= n >> i;
	}
	++n;
	return n;
}

bool is_power_of_2(size_t n)
{
	return (n != 0) && (n & (n - 1)) == 0;
}
