/*
 *  linux/lib/dup.c
 *
 *  (C) 1991  Linus Torvalds
 *   复制文件描述符函数
 */

#define __LIBRARY__
#include <unistd.h>

_syscall1(int,dup,int,fd)
