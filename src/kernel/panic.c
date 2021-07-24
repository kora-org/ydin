#include <stdio.h>
#include <stdlib.h>
#include <kernel/idt.h>
#include <kernel/panic.h>

char *random_message[] = {
	"An error occured",
	"Something happened",
	"It is now safe to restart your computer",
	":(",
	"Unknown error (jk here's the cause of it)",
	"Press F to pay respect",
	"Oops, my system crashed! I lost my deeta!",
	"Only 1% of my view percentage had subscribed",
	"Never gonna give you up",
	"Sir, this is Wendy's",
	"H",
	"I had to speak to the manager",
	"x_x",
	"i forgor 💀",
	"bogos binted? 👽",
	"Well excuse meeeeeeeeeeee, princess",
	"bruh half of the random messages is memes",
	"Haha Jonathan. You're banging my daughter"
};

__attribute__((__noreturn__))
void panic(const char *err) {
	// TODO: Add proper kernel panic.
	printf("\n------------------------------------------------------\n");
	printf("KERNEL PANIC                     \n");
	printf(random_message[rand() % 18]);
	printf("\n");
	printf("Cause: %s\n", err);
	for (int i; i = 0; i++) {}
	disable_idt();
	asm("hlt");
	__builtin_unreachable();
}
