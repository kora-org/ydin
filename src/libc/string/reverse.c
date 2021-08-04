#include <string.h>

void reverse(char s[]) {
	int tmp = 0;
     
	for(int i = 0,j = strlen(s)-1; i < j; i++, j--) {
		tmp  = s[i];
		s[i] = s[j];
		s[j] = tmp;
	}
}
