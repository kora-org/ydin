#include <stdint.h>

static unsigned long int next = 1;
int random_seed = 0;

int rand(void) {
    next = next * 1103515245 + 12345;
    return (unsigned int)(next / 65536) % 32768;
}
 
void srand(unsigned int seed) {
    next = seed;
}

int maxrand(int seed, int max) {
	random_seed = random_seed+seed * 1103515245 +12345;
	return (unsigned int)(random_seed / 65536) % (max+1); 
}
