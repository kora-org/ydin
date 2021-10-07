# Note
FaruOS is going under a rewrite. This is because I'm tried of my awful and copypasted code. You can see the rewritten code [here](https://github.com/leapofazzam123/faruos/tree/rewrite)

# <p align="center">![FaruOS](logo_w_bg.png)</p>
<p align="center">A simple operating system, made with stivale2 and limine</p>

###### <p align="center">![Made with C](https://forthebadge.com/images/badges/made-with-c.svg) ![Gluten-free](https://forthebadge.com/images/badges/gluten-free.svg) ![Built with <3](https://forthebadge.com/images/badges/built-with-love.svg) [![Support Server](https://img.shields.io/discord/870148344205443073.svg?label=&logo=discord&logoColor=ffffff&color=5865F2&style=for-the-badge)](https://discord.gg/KvbDSaF5fr)</p>
<!-- centered image with link doesn't work outside header -->

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

## Acknowledgement
* [limine-barebones](https://github.com/limine-bootloader/limine-barebones)/[stivale2-barebones](https://github.com/limine-bootloader/limine-barebones/tree/master/stivale2-barebones) and [OSDev Wiki](https://wiki.osdev.org/) [Stivale Bare Bones](https://wiki.osdev.org/Stivale_Bare_Bones) for the base
* [Meaty Skeleton](https://wiki.osdev.org/Meaty_Skeleton) for libc implementation
* [HhhOS](https://git.hippoz.xyz/tunacangamer/HhhOS/) for interrupt implementation (thats a very obscure source tbh)
* And a bunch of other stuff, licensed with GPL, LGPL, BSD, MIT, and Apache license

## License
<a href="https://www.gnu.org/licenses/agpl-3.0.en.html"><img align="right" height="54" alt="GNU AGPL v3 logo" src="https://upload.wikimedia.org/wikipedia/commons/0/06/AGPLv3_Logo.svg"/></a>
The FaruOS operating system and some of it's components are licensed under GNU Affero General Public License.

The full text of the license can be accessed via this [link](https://www.gnu.org/licenses/agpl-3.0.en.html) and is also included in the [license file](LICENSE) of this software package.
