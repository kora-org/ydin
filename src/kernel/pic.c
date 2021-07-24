#include <kernel/io.h>
#include <kernel/pic.h>

void init_pic() {
	// ICW1
	outb(PIC1_PORT_A, 0x11);
	io_wait();
	outb(PIC2_PORT_A, 0x11);
	io_wait();
	// ICW2
	outb(PIC1_DATA, PIC1_PORT_A);
	io_wait();
	outb(PIC2_DATA, PIC2_PORT_A);
	io_wait();
	// ICW3
	outb(PIC1_DATA, 0x00);
	io_wait();
	outb(PIC2_DATA, 0x00);
	io_wait();
	// ICW4
	outb(PIC1_DATA, 0x01);
	io_wait();
	outb(PIC2_DATA, 0x01);
	io_wait();
	// Mask interrupts and disable PIC (for APIC usage)
	outb(PIC1_DATA, 0xff);
	io_wait();
	outb(PIC2_DATA, 0xff);
	io_wait();
}

/** pic_sendAck:
 *  Acknowledges an interrupt from either PIC 1 or PIC 2.
 *
 *  @param num The number of the interrupt
 */
void pic_sendAck(unsigned int interrupt) {
	if (interrupt < PIC1_START_INTERRUPT || interrupt > PIC2_END_INTERRUPT) {
		return;
	}

	if (interrupt < PIC2_START_INTERRUPT) {
		outb(PIC1_PORT_A, PIC_ACK);
	} else {
		outb(PIC2_PORT_A, PIC_ACK);
	}
}
