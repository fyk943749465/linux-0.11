/*定义了进程中运行的时间结构tms以及times函数原形*/
#ifndef _TIMES_H
#define _TIMES_H

#include <sys/types.h>

struct tms {            // 文件访问与修改时间结构
	time_t tms_utime;   // 用户使用的CPU时间
	time_t tms_stime;   // 系统(内核)使用的CPU时间
	time_t tms_cutime;  // 已终止的子进程使用的用户CPU时间
	time_t tms_cstime;  // 已终止的子进程使用的系统CPU时间
};

extern time_t times(struct tms * tp);

#endif
