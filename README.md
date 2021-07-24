# <p align="center">![FaruOS](logo_w_bg.png)</p>
<p align="center">A simple operating system, made with stivale2 and limine</p>

## Requirements
* LLVM/Clang (because compiling x86-64-elf-gcc is a pain in the butt)

## How to compile
* Install LLVM and Clang
	* Ubuntu/Debian
	```
	apt install make binutils llvm clang
	```
	* Arch Linux
	```
	pacman -S make binutils llvm clang
	```
* Compile using make
```
make
```

## Progress
- [x] Displaying a basic "Hello World" on the screen
- [x] Implement a libc
- [x] Give the OS a name
- [ ] Making a basic shell
- [ ] Making the OS POSIX compliant
- [ ] Implement an ELF binary loader
- [ ] Implement a GUI

## Sources
* [limine-barebones](https://github.com/limine-bootloader/limine-barebones)/[stivale2-barebones](https://github.com/limine-bootloader/limine-barebones/tree/master/stivale2-barebones) and [OSDev Wiki](https://wiki.osdev.org/) [Stivale Bare Bones](https://wiki.osdev.org/Stivale_Bare_Bones) for the base
* [Meaty Skeleton](https://wiki.osdev.org/Meaty_Skeleton) for libc implementation
* [HhhOS](https://git.hippoz.xyz/tunacangamer/HhhOS/) for interrupt implementation (thats a very obscure source bruh)
* And a bunch of other stuff, licensed with GPL, LGPL, BSD, MIT, and Apache license
