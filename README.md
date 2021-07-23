# <p align="center"><img src="logo.png" width="200px" /></p>
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
