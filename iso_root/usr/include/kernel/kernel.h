#include <stdint.h>
#include <stddef.h>
#include <stivale/stivale2.h>

static struct stivale2_header_tag_terminal terminal_hdr_tag;
static struct stivale2_header_tag_framebuffer framebuffer_hdr_tag;
struct stivale2_header_tag_terminal *term_str_tag;
void *term_write_ptr;
uint16_t *term_cols;
uint16_t *term_rows;
uint8_t *fb_addr;
extern void (*term_write)(const char *string, size_t length);
void *stivale2_get_tag(struct stivale2_struct *stivale2_struct, uint64_t id);
