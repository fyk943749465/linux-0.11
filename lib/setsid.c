/*
 *  linux/lib/setsid.c
 *
 *  (C) 1991  Linus Torvalds
 *   创建辉煌的系统调用
 */

#define __LIBRARY__
#include <unistd.h>

_syscall0(pid_t,setsid)
