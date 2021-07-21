#include <stdio.h>
#include <kernel/fb.h>
 
int putchar(int ic) {
	char c = (char) ic;
	term_write(&c, sizeof(c));
	return ic;
}
