#include <stdint.h>

#define PIC1_PORT_A 0x20
#define PIC2_PORT_A 0xA0

#define PIC1_COMMAND    PIC1_PORT_A
#define PIC1_DATA   (PIC1_PORT_A+1)
#define PIC2_COMMAND    PIC2_PORT_A
#define PIC2_DATA   (PIC2_PORT_A+1)

#define ICW1 0x11
#define ICW4 0x01

/* The PIC interrupts have been remapped */
#define PIC1_START_INTERRUPT 0x20
#define PIC2_START_INTERRUPT 0x28
#define PIC2_END_INTERRUPT   PIC2_START_INTERRUPT + 7

#define PIC_ACK     0x20

void init_pic();
void pic_sendAck(unsigned int interrupt);
