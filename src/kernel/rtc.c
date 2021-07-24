#include <stdint.h>
#include <kernel/io.h>
#include <kernel/idt.h>
#include <kernel/rtc.h>

/* Check if RTC is updating */
static int is_updating()
{
    outb(0x70, 0x0A);
    return inb(0x71) & 0x80;
}

static unsigned char read(int reg)
{
    while (is_updating())
        ;
    outb(0x70, reg);

    return inb(0x71);
}

unsigned char rtc_get_seconds()
{
    unsigned char seconds = read(0);
    unsigned char second = (seconds & 0x0F) + ((seconds / 16) * 10);
    return second;
}

unsigned char rtc_get_minutes()
{
    unsigned char minutes = read(0x2);
    unsigned char minute = (minutes & 0x0F) + ((minutes / 16) * 10);
    return minute;
}

unsigned char rtc_get_hours()
{
    unsigned char hours = read(0x4);
    unsigned char hour = ((hours & 0x0F) + (((hours & 0x70) / 16) * 10)) | (hours & 0x80);
    return hour;
}

Time rtc_get_time()
{
    Time time;
    time.hour = rtc_get_hours();
    time.minute = rtc_get_minutes();
    time.second = rtc_get_seconds();
    return time;
}

DateTime rtc_get_date_time()
{
    DateTime date_time;

    date_time.day = read(0x7);
    date_time.month = read(0x8);
    date_time.year = read(0x9);

    date_time.time = rtc_get_time();

    return date_time;
}
