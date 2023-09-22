/*时间类型头文件,主要定义了tm结构和一些有关时间的函数原形*/
#ifndef _TIME_H
#define _TIME_H

#ifndef _TIME_T
#define _TIME_T
typedef long time_t;
#endif

#ifndef _SIZE_T
#define _SIZE_T
typedef unsigned int size_t;
#endif

#define CLOCKS_PER_SEC 100

typedef long clock_t;

struct tm {         // 时间结构
	int tm_sec;     // 秒数[0,59]
	int tm_min;     // 分钟数[0,59]
	int tm_hour;    // 小时数[0,59]
	int tm_mday;    // 一个月的天数[0,31]
	int tm_mon;     // 一年中的月份[0,11]
	int tm_year;	// 从1900年开始的年数
	int tm_wday;    // 1星期中的某天[0,6](星期天=0)
	int tm_yday;    // 一年中的某天[0,365]
	int tm_isdst;   // 夏令时标志
};

clock_t clock(void);
time_t time(time_t * tp);
double difftime(time_t time2, time_t time1);
time_t mktime(struct tm * tp);

char * asctime(const struct tm * tp);
char * ctime(const time_t * tp);
struct tm * gmtime(const time_t *tp);
struct tm *localtime(const time_t * tp);
size_t strftime(char * s, size_t smax, const char * fmt, const struct tm * tp);
void tzset(void);

#endif
