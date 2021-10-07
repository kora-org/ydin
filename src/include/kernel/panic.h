#pragma once
#include <stdint.h>

void __panic(char *file, const char function[20], int line, char *message);
#define panic(msg) __panic(__FILE_NAME__, __FUNCTION__, __LINE__, msg);
