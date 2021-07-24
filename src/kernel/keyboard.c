#include <stdint.h>
#include <stdbool.h>
#include <kernel/io.h>
#include <kernel/idt.h>
#include <kernel/pic.h>
#include <kernel/keyboard.h>

/** read_scan_code:
 *  Reads a scan code from the keyboard
 *
 *  @return The scan code (NOT an ASCII character!)
 */
unsigned char read_scan_code(void) {
	char c;
	c = inb(KBD_DATA_PORT);
	return c;
}

unsigned char get_key_char(void) {
	int i;
	char key;
	uint8_t state = inb(0x64);
	while (state & 1 && (state & 0x20) == 0) {
		uint8_t keycode = inb(0x60);
		uint8_t scan_code = keycode & 0x7f;
		uint8_t key_state = !(keycode & 0x80);
		
        if (key_state) {
            return kbdus[(unsigned char)scan_code];
        }

        state = inb(0x64);
	}
	outb(0x20, 0x20);
	return 0;
}
