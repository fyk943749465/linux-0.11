/*用户时间头文件,定义了访问和修改时间结构以及utime()原型*/
#ifndef _UTIME_H
#define _UTIME_H

#include <sys/types.h>	/* I know - shouldn't do this, but .. */

struct utimbuf {         // 文件访问/修改结构
	time_t actime;       // 文件访问时间,从1970.1.1:0:0:0 开始的秒数
	time_t modtime;      // 文件修改时间,从1970.1.1:0:0:0 开始的秒数
};

extern int utime(const char *filename, struct utimbuf *times);

#endif
