# osdev
My hobby OS development, made with stivale2 and limine

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
- [-] Implementing libc
- [-] Give the OS a name 
- [] Making a basic shell
- [] Making the OS POSIX compliant
- [] Implementing an ELF binary loader
- [] Implementing a GUI
