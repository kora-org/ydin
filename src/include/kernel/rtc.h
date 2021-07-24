#include <stdint.h>

typedef struct
{
    uint32_t hour;
    uint32_t second;
    uint32_t minute;

} Time;

typedef struct
{
  uint32_t day;
  uint32_t month;
  uint32_t year;
  Time time;
} DateTime;

void rtc_init();
unsigned char rtc_get_seconds();
unsigned char rtc_get_minutes();
unsigned char rtc_get_hours();
Time rtc_get_time();
DateTime rtc_get_date_time();
