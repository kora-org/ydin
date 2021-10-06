#pragma once
#include <stdint.h>

inline void outb(uint16_t port, uint8_t val);
inline uint8_t inb(uint16_t port);
inline void outw(uint16_t port, uint16_t val);
inline uint16_t inw(uint16_t port);
inline void outl(uint16_t port, uint32_t val);
inline uint32_t inl(uint16_t port);
