/*
 *  linux/kernel/mktime.c
 *
 *  (C) 1991  Linus Torvalds
 * 通用程序
 * 包含一个内核使用的时间函数mktime(),用于计算从1970年1月1日0时起到开机当日的秒数,作为开机时间.
 * 仅在 init/main.c中被调用一次
 */

#include <time.h>

/*
 * This isn't the library routine, it is only used in the kernel.
 * as such, we don't care about years<1970 etc, but assume everything
 * is ok. Similarly, TZ etc is happily ignored. We just do everything
 * as easily as possible. Let's find something public for the library
 * routines (although I think minix times is public).
 */
/*
 * PS. I hate whoever though up the year 1970 - couldn't they have gotten
 * a leap-year instead? I also hate Gregorius, pope or no. I'm grumpy.
 */
/*
 * 这不是库函数,它仅供内核使用.因此我们不关系小于 1970 年的年份等,但假定一切均很正常.
 * 同样,时间区域 TZ 问题也先忽略. 我们只是尽可能简单地处理问题. 最好能找到一些公开的
 * 库函数(尽管我们认为 minix的时间函数是公开的)
 * 另外,我恨那个设置 1970 年开始的人, 难道他们就不能选择从一个闰年开始? 
 */
#define MINUTE 60                 // 1 分钟的秒数
#define HOUR (60*MINUTE)          // 1 小时的秒数
#define DAY (24*HOUR)             // 1 天的秒数
#define YEAR (365*DAY)            // 1 年的秒数

/* interestingly, we assume leap-years */
/* 有趣的是我们考虑进了闰年 */
// 下面以年为界限,定义了每个月开始时的秒数时间数组
static int month[12] = {
	0,
	DAY*(31),
	DAY*(31+29),
	DAY*(31+29+31),
	DAY*(31+29+31+30),
	DAY*(31+29+31+30+31),
	DAY*(31+29+31+30+31+30),
	DAY*(31+29+31+30+31+30+31),
	DAY*(31+29+31+30+31+30+31+31),
	DAY*(31+29+31+30+31+30+31+31+30),
	DAY*(31+29+31+30+31+30+31+31+30+31),
	DAY*(31+29+31+30+31+30+31+31+30+31+30)
};

// 该函数计算从 1970年1月1日0时起到开机当日警告的秒数,作为开机时间.
long kernel_mktime(struct tm * tm)
{
	long res;
	int year;

	year = tm->tm_year - 70;            // 从 70年到现在经过的年数(2位表示方式)
										// 因此会有 2000 年问题
/* magic offsets (y+1) needed to get leapyears right.*/
	// 为了获得正确的闰年数,这里需要这样一个魔幻偏值(y+1)
	res = YEAR*year + DAY*((year+1)/4);         // 这些年经过的秒数时间 + 每个闰年多1天
	res += month[tm->tm_mon];                   // 的秒数时间,再加上当年到单月时的秒数
/* and (y+2) here. If it wasn't a leap-year, we have to adjust */

	// 以及 y+2. 如果y+2不是闰年,那么我们就必须进行调整(减去一天的秒数时间).
	if (tm->tm_mon>1 && ((year+2)%4))
		res -= DAY;
	res += DAY*(tm->tm_mday-1);      // 再加上本月过去的天数的秒数时间
	res += HOUR*tm->tm_hour;         // 再加上当天国庆的小时数的秒数时间
	res += MINUTE*tm->tm_min;        // 再加上1小时内过去的分钟数的秒数时间
	res += tm->tm_sec;               // 再加上1分钟内已过去的秒数
	return res;                      // 即等于从 1970 年以来经过的秒数时间
}
