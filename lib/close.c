/*
 *  linux/lib/close.c
 *
 *  (C) 1991  Linus Torvalds
 *   �ر��ļ�
 */

#define __LIBRARY__
#include <unistd.h>

_syscall1(int,close,int,fd)
