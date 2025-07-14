#include <regex.h>
#include <stdbool.h>
#include <stdalign.h>
#include <stddef.h>

bool isMatch(regex_t *re, char const *input) {
  return regexec(re, input, 0, NULL, 0) == 0;
}
