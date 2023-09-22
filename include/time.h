/*ʱ������ͷ�ļ�,��Ҫ������tm�ṹ��һЩ�й�ʱ��ĺ���ԭ��*/
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

struct tm {         // ʱ��ṹ
	int tm_sec;     // ����[0,59]
	int tm_min;     // ������[0,59]
	int tm_hour;    // Сʱ��[0,59]
	int tm_mday;    // һ���µ�����[0,31]
	int tm_mon;     // һ���е��·�[0,11]
	int tm_year;	// ��1900�꿪ʼ������
	int tm_wday;    // 1�����е�ĳ��[0,6](������=0)
	int tm_yday;    // һ���е�ĳ��[0,365]
	int tm_isdst;   // ����ʱ��־
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
