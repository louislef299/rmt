#include <regex.h>
#include <stdbool.h>
#include <stdalign.h>
#include <stddef.h>

const size_t sizeof_regex_t = sizeof(regex_t);
const size_t alignof_regex_t = alignof(regex_t);

bool isMatch(regex_t *re, char const *input);
