#include "dtmf_private.h"

#include "utils.h"
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SPECIAL_BUTTON_CHAR '*'

static dtmf_button_t *get_closest_button(uint16_t row_freq, uint16_t col_freq);

#if 1
dtmf_button_t buttons[] = {
	{ .index = 0, .characters = "1", .row_freq = 697, .col_freq = 1209 },
	{ .index = 1, .characters = "2abc", .row_freq = 697, .col_freq = 1336 },
	{ .index = 2, .characters = "3def", .row_freq = 697, .col_freq = 1477 },
	{ .index = 3, .characters = "4ghi", .row_freq = 770, .col_freq = 1209 },
	{ .index = 4, .characters = "5jkl", .row_freq = 770, .col_freq = 1336 },
	{ .index = 5, .characters = "6mno", .row_freq = 770, .col_freq = 1477 },
	{ .index = 6, .characters = "7pqrs", .row_freq = 852, .col_freq = 1209 },
	{ .index = 7, .characters = "8tuv", .row_freq = 852, .col_freq = 1336 },
	{ .index = 8, .characters = "9wxyz", .row_freq = 852, .col_freq = 1477 },
	{ .index = 9, .characters = "#.!?,", .row_freq = 941, .col_freq = 1209 },
	{ .index = 10, .characters = "0 ", .row_freq = 941, .col_freq = 1336 },
	{ .index = 11, .characters = "*", .row_freq = 941, .col_freq = 1477 },
};
#else

dtmf_button_t buttons[] = {
	{ .index = 0, .characters = "1", .row_freq = 697, .col_freq = 1209 },
	{ .index = 1, .characters = "abc2", .row_freq = 697, .col_freq = 1336 },
	{ .index = 2, .characters = "def3", .row_freq = 697, .col_freq = 1477 },
	{ .index = 3, .characters = "ghi4", .row_freq = 770, .col_freq = 1209 },
	{ .index = 4, .characters = "jkl5", .row_freq = 770, .col_freq = 1336 },
	{ .index = 5, .characters = "mno6", .row_freq = 770, .col_freq = 1477 },
	{ .index = 6, .characters = "pqrs7", .row_freq = 852, .col_freq = 1209 },
	{ .index = 7, .characters = "tuv8", .row_freq = 852, .col_freq = 1336 },
	{ .index = 8, .characters = "wxyz9", .row_freq = 852, .col_freq = 1477 },
	{ .index = 9, .characters = "#.!?,", .row_freq = 941, .col_freq = 1209 },
	{ .index = 10, .characters = " 0", .row_freq = 941, .col_freq = 1336 },
	{ .index = 11, .characters = "*", .row_freq = 941, .col_freq = 1477 },
};
#endif

dtmf_button_t *dtmf_get_button(char value)
{
	for (size_t i = 0; i < ARRAY_LEN(buttons); ++i) {
		if (strchr(buttons[i].characters, value) != NULL) {
			return &buttons[i];
		}
	}
	return NULL;
}
size_t dtmf_get_times_to_push(size_t btn_nr, char value, size_t extra_presses)
{
	assert(btn_nr < ARRAY_LEN(buttons));

	const char *char_btn_position =
		strchr(buttons[btn_nr].characters, value);

	assert(char_btn_position);

	const size_t index = char_btn_position - buttons[btn_nr].characters + 1;
	return index + (strlen(buttons[btn_nr].characters) * extra_presses);
}

char dtmf_decode_character(dtmf_button_t *button, size_t presses)
{
	assert(button);

	if (button->index + 1 == ARRAY_LEN(buttons)) {
		printf("Detected button %zu which should never happen and means the encoding is not very good :(\n",
		       button->index + 1);
		printf("\tUsing %c to represent this button\n",
		       button->characters[0]);
		return button->characters[0];
	}
	const char *characters = button->characters;
	return characters[(presses - 1) % strlen(characters)];
}

dtmf_button_t *dtmf_get_closest_button(uint16_t f1, uint16_t f2)
{
	if (f1 > f2) {
		return get_closest_button(f2, f1);
	}
	return get_closest_button(f1, f2);
}

dtmf_button_t *dtmf_get_button_by_index(size_t index)
{
	return &buttons[index];
}
int32_t s(int32_t a, uint32_t f1, uint32_t f2, uint32_t t, uint32_t sample_rate)
{
	return a * (sin(2. * M_PI * f1 * t / sample_rate) +
		    sin(2. * M_PI * f2 * t / sample_rate));
}
static dtmf_button_t *get_closest_button(uint16_t row_freq, uint16_t col_freq)
{
	dtmf_button_t *closest = NULL;
	uint16_t row_diff = 0xFFFF, col_diff = 0xFFFF;
	for (size_t i = 0; i < ARRAY_LEN(buttons); ++i) {
		const uint16_t row_d = abs(buttons[i].row_freq - (int)row_freq);
		const uint16_t col_d = abs(buttons[i].col_freq - (int)col_freq);
		if (row_d < row_diff || col_d < col_diff) {
			closest = &buttons[i];
			row_diff = row_d;
			col_diff = col_d;
		}
	}
	return closest;
}
